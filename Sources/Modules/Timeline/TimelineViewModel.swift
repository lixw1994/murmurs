import Foundation
import XLog
import SwiftData
import SwiftUI
import Observation

@MainActor @Observable final class TimelineViewModel {
    var showDeleteAlert = false
    var memoToDelete: MemoEntity? {
        didSet {
            if memoToDelete != nil {
                showDeleteAlert = true
            }
        }
    }
    var memoToShare: MemoEntity?

    var transcribingMemos = Set<MemoEntity>()
    var polishingMemos = Set<MemoEntity>()
    var syncingMemos = Set<MemoEntity>()
    var failedMemos = [MemoEntity: Error]()
    var polishFailedMemos = [MemoEntity: Error]()
    var showReviewDialog = false

    var isHoldingToRecord = false

    var isMultiSelectMode = false
    var selectedMemos = Set<MemoEntity>()

    let recorder: any AudioRecorderProtocol

    @ObservationIgnored @AppStorage("requested_review_at") var requestedReviewAt = Date(timeIntervalSince1970: 0).timeIntervalSince1970

    private let transcription: TranscriptionServiceProtocol
    private let readwiseClient: ReadwiseClientProtocol
    private let aiClient: AIClientProtocol
    private let context: ModelContext
    private let notificationCenter: NotificationCenter
    private let config: any ConfigProtocol
    private var transCount = 0

    init(transcription: TranscriptionServiceProtocol = Transcription.shared,
         context: ModelContext = DataContainer.shared.context,
         notificationCenter: NotificationCenter = .default,
         config: any ConfigProtocol = Config.shared,
         recorder: any AudioRecorderProtocol = AudioRecorder(),
         readwiseClient: ReadwiseClientProtocol = ReadwiseClient.shared,
         aiClient: AIClientProtocol = OpenAIClient.shared) {
        self.transcription = transcription
        self.context = context
        self.notificationCenter = notificationCenter
        self.config = config
        self.recorder = recorder
        self.readwiseClient = readwiseClient
        self.aiClient = aiClient
        notificationCenter.addObserver(self, selector: #selector(handleMemoInserted), name: .memoInserted, object: nil)
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    @objc private func handleMemoInserted(_ notification: Notification) {
        guard let memo = notification.object as? MemoEntity else { return }

        if config.transEnabled && memo.needsTranscription {
            transcribe(memo)
            return
        }

        if config.readwiseAutoSync {
            syncToReadwise(memo)
        }
    }

    func transcribe(_ memo: MemoEntity) {
        guard memo.file != nil else { return }
        failedMemos[memo] = nil
        transcribingMemos.insert(memo)
        transcription.transcribe(memo) { [weak self] result in
            self?.transcribingMemos.remove(memo)
            switch result {
            case .success(let text):
                if memo.content != text {
                    memo.content = text
                    memo.transcribed = true
                    memo.updatedAt = Date()
                    try? self?.context.save()
                    self?.transCount += 1
                    self?.requestReview()
                    if self?.config.readwiseAutoSync == true {
                        self?.syncToReadwise(memo)
                    }
                }
            case .failure(let error):
                self?.failedMemos[memo] = error
                XLog.error(error, source: "Timeline")
            }
        }
    }

    func toggleVisibility(_ memo: MemoEntity) {
        memo.isHidden.toggle()
        do {
            try context.save()
        } catch {
            XLog.error(error, source: "Timeline")
        }
    }

    private func requestReview() {
        guard transCount > 5 else { return }
        let timeInterval = Date().timeIntervalSince1970
        if timeInterval - requestedReviewAt > 3600 * 24 * 10 {
            showReviewDialog = true
            requestedReviewAt = timeInterval
        }
    }

    func syncToReadwise(_ memo: MemoEntity) {
        guard config.isReadwiseSet else { return }
        guard memo.needsSync else { return }
        guard !syncingMemos.contains(memo) else { return }

        syncingMemos.insert(memo)
        Task {
            do {
                let documentId = try await readwiseClient.save(memo: memo)
                memo.readwiseId = documentId
                memo.syncedAt = Date()
                try? context.save()
            } catch {
                XLog.error("Readwise sync failed: \(error)", source: "Timeline")
            }
            syncingMemos.remove(memo)
        }
    }

    func unsyncFromReadwise(_ memo: MemoEntity) {
        guard memo.readwiseId != nil else { return }
        guard !syncingMemos.contains(memo) else { return }

        syncingMemos.insert(memo)
        Task {
            do {
                try await readwiseClient.delete(documentId: memo.readwiseId!)
                memo.readwiseId = nil
                memo.syncedAt = nil
                try? context.save()
            } catch {
                XLog.error("Readwise unsync failed: \(error)", source: "Timeline")
            }
            syncingMemos.remove(memo)
        }
    }

    func polish(_ memo: MemoEntity) {
        guard config.isServerSet else {
            polishFailedMemos[memo] = OpenAIError.badResponse(L(.polish_server_not_set))
            return
        }
        guard !memo.viewContent.isEmpty else { return }
        guard !polishingMemos.contains(memo) else { return }

        polishFailedMemos[memo] = nil
        polishingMemos.insert(memo)

        Task {
            do {
                let stream = try await aiClient.polish(memo.viewContent, model: config.aiModel)
                var result = ""
                for try await text in stream {
                    result += text
                }
                // Trim trailing newline that streaming may add
                let polished = result.trimmingCharacters(in: .whitespacesAndNewlines)
                if !polished.isEmpty {
                    memo.polishedContent = polished
                    memo.updatedAt = Date()
                    try? context.save()
                }
            } catch {
                polishFailedMemos[memo] = error
                XLog.error(error, source: "Timeline")
            }
            polishingMemos.remove(memo)
        }
    }

    func deletePolish(_ memo: MemoEntity) {
        memo.polishedContent = nil
        memo.updatedAt = Date()
        do {
            try context.save()
        } catch {
            XLog.error(error, source: "Timeline")
        }
    }

    func beginHoldToRecord() {
        recorder.startRecording()
        isHoldingToRecord = true
    }

    func endHoldToRecord() {
        isHoldingToRecord = false
        recorder.didCompleteCallback = { [weak self] in
            guard let self = self, let url = self.recorder.voiceFile else {
                return
            }
            self.saveVoice(url)
        }
        recorder.stopRecording()
    }

    func cancelHoldToRecord() {
        recorder.terminate()
        isHoldingToRecord = false
    }

    private func saveVoice(_ voiceURL: URL) {
        guard let voiceURL = recorder.voiceFile else { return }
        let memo = MemoEntity(file: voiceURL.lastPathComponent)
        context.insert(memo)
        do {
            try context.save()
            _ = try FileHelper.moveAudioFile(voiceURL)
            NotificationCenter.default.post(name: .memoInserted, object: memo)
        } catch {
            XLog.error(error, source: "recording")
        }
    }

    func toggleMemoSelection(_ memo: MemoEntity) {
        if selectedMemos.contains(memo) {
            selectedMemos.remove(memo)
        } else {
            selectedMemos.insert(memo)
        }
    }

    func deleteSelectedMemos(context: ModelContext) {
        if isMultiSelectMode {
            MemoEntity.deleteMemos(context: context, memos: selectedMemos)
            selectedMemos.removeAll()
            isMultiSelectMode = false
            memoToDelete = nil
        } else {
            guard let memo = memoToDelete else { return }
            MemoEntity.delete(context: context, memo: memo)
            memoToDelete = nil
        }
    }

}
