import Foundation
import SwiftData
import XLog
import Observation

@MainActor @Observable final class RecordingCompletedViewModel {
    var voiceURL: URL
    let context: ModelContext
    let config: any ConfigProtocol
    private let transcription: TranscriptionServiceProtocol
    private let appendTo: MemoEntity?

    var hasTranscribed = false
    var isTranscribing = false
    var transcribedText: String? {
        didSet {
            hasTranscribed = true
            content = transcribedText ?? ""
        }
    }

    var transcriptionError: String?
    var saved = false
    var content = ""
    var duration: Double = 0
    var canBeSaved: Bool = false

    var isAppendMode: Bool { appendTo != nil }

    init(voicePath: URL,
         preTranscribedText: String? = nil,
         appendTo: MemoEntity? = nil,
         context: ModelContext = DataContainer.shared.context,
         config: any ConfigProtocol = Config.shared,
         transcription: TranscriptionServiceProtocol = Transcription.shared) {
        self.voiceURL = voicePath
        self.appendTo = appendTo
        self.context = context
        self.config = config
        self.transcription = transcription

        if let preTranscribedText {
            self.transcribedText = preTranscribedText
        }

        Task { @MainActor in
            duration = await FileHelper.getAudioDuration(voiceURL)
            canBeSaved = true
        }
    }

    deinit {
        #if DEBUG
            XLog.debug("✖︎ RecordingCompletedViewModel", source: "Recording")
        #endif
    }

    func transcribe() {
        guard config.transEnabled else { return }
        guard isTranscribing == false else { return }
        guard !hasTranscribed else { return } // Skip if already pre-transcribed

        Task { @MainActor in
            isTranscribing = true
            do {
                let txt = try await transcription.transcribe(voiceURL: voiceURL, provider: config.transProvider, lang: config.transLang)
                transcribedText = txt
            } catch {
                transcriptionError = ErrorHelper.desc(error)
            }
            isTranscribing = false
        }
    }

    func save() {
        if let memo = appendTo {
            let transcribedText = hasTranscribed ? content : nil
            NotificationCenter.default.post(
                name: .memoAppendRecording,
                object: memo,
                userInfo: ["voiceURL": voiceURL, "transcribedText": transcribedText as Any]
            )
            saved = true
            return
        }

        let memo = MemoEntity(content: content, file: voiceURL.lastPathComponent, duration: duration)
        memo.transcribed = hasTranscribed
        context.insert(memo)
        do {
            try context.save()
            _ = try FileHelper.moveAudioFile(voiceURL)
            saved = true
            NotificationCenter.default.post(name: .memoInserted, object: memo)
        } catch {
            XLog.error(error, source: "recording")
        }
    }

    func delete() {
        do {
            XLog.debug("Deleting temporary audio file at \(voiceURL.absoluteString)", source: "recording")
            try FileManager.default.removeItem(at: voiceURL)
        } catch {
            XLog.error(error, source: "recording")
        }
    }
}
