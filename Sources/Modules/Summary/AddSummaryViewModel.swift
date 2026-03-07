import Foundation
import SwiftData
import XLog
import Observation

@MainActor @Observable final class AddSummaryViewModel {
    let item: SummaryItem
    let context: ModelContext

    var defaultTitle = ""
    var dayId = 0

    var selectedPrompt: PromptEntity? {
        didSet {
            if let prompt = selectedPrompt {
                temperature = prompt.temperature
            }
        }
    }

    var temperature = 0.5
    var promptToEdit: PromptEntity?
    var showAddPrompt: Bool = false

    var fatalErrorMessage = "" {
        didSet {
            showFatalError = true
        }
    }
    var showFatalError = false
    var memoContent = ""
    var summaryMessage = ""
    var summaryMessageCharCount: Int { summaryMessage.count }

    var navPath: [AddSummaryNavPath] = []

    var isSummarizing = false
    var summarizedResponse = ""
    var summaryError = ""
    var saved = false
    var model: OpenAIChatModel = .gpt_4o_mini

    var validMemos = [MemoEntity]()
    var excludedMemos = Set<MemoEntity>() {
        didSet { selectedMemos = validMemos.filter { !excludedMemos.contains($0) } }
    }
    var selectedMemos = [MemoEntity]()

    private var cancellationTask: Task<Void, Never>? = nil
    private let aiClient: AIClientProtocol
    private let store: MemoStoreProtocol
    private let config: any ConfigProtocol

    init(item: SummaryItem,
         context: ModelContext,
         aiClient: AIClientProtocol = OpenAIClient.shared,
         store: MemoStoreProtocol = DataContainer.shared,
         config: any ConfigProtocol = Config.shared) {
        self.item = item
        self.context = context
        self.aiClient = aiClient
        self.store = store
        self.config = config

        if case let .day(id) = item {
            dayId = id
        }

        self.defaultTitle = L(.sum_title_default, DateHelper.formatIdentifier(dayId, dateFormat: "yyyy-MM-dd"))
    }

    deinit {
        #if DEBUG
            XLog.debug("✖︎ AddSummaryViewModel", source: "Summary")
        #endif
    }

    func fetchEntries() {
        let dayId32 = Int32(dayId)
        var descriptor = FetchDescriptor<MemoEntity>(
            predicate: #Predicate { $0.day == dayId32 },
            sortBy: [SortDescriptor(\MemoEntity.createdAt)]
        )
        var ret = ""
        do {
            let memos = try context.fetch(descriptor).filter { !$0.viewContent.isEmpty }
            validMemos = memos
            selectedMemos = memos
            for memo in memos {
                ret.append("\n[\(memo.viewTime)] \(memo.viewContent)\n")
            }

            if ret.count < Constants.Summary.lengthLimit {
                fatalErrorMessage = L(.sum_text_too_short)
            } else {
                memoContent = ret
            }
        } catch {
            XLog.error(error, source: "Sumary")
        }
    }

    func generateMessage() {
        guard let prompt = selectedPrompt else { return }

        var content = ""
        for memo in selectedMemos {
            content.append("\n[\(memo.viewTime)] \(memo.viewContent)\n")
        }

        if content.count < Constants.Summary.lengthLimit {
            fatalErrorMessage = L(.sum_text_too_short)
        }

        var ret = replacePlaceHolders(prompt.viewContent)
        ret.append("\n\n------")
        ret.append(content)
        ret.append("------\n")
        summaryMessage = ret
    }

    func replacePlaceHolders(_ message: String) -> String {
        var ret = message
        let items = [
            "date": DateHelper.formatIdentifier(dayId),
        ]
        for (key, value) in items {
            ret = ret.replacingOccurrences(of: "{{\(key)}}", with: "\(value)")
        }
        return ret
    }

    func summarize() {
        if isSummarizing { return }

        if !config.isServerValid {
            summaryError = L(.error_invalid_custom_server)
            return
        }

        let server = config.serverHost
        model = config.aiModel

        XLog.info("Summarize (prompt: \(selectedPrompt?.viewTitle ?? ""), server: \(server), temp: \(temperature), model: \(model.name))", source: "Summary")

        cancellationTask = Task { @MainActor in
            isSummarizing = true
            do {
                summaryError = ""
                summarizedResponse = ""
                let stream = try await aiClient.summarize(summaryMessage, model: model, temperature: temperature)
                for try await text in stream {
                    if summarizedResponse == "" {
                        XLog.info("Sent characters = \(summaryMessageCharCount)", source: "Summary")
                        store.recordUsage(charsSent: summaryMessageCharCount, charsReceived: 0, whisper: 0)
                    }
                    summarizedResponse += text
                }
            } catch {
                summaryError = ErrorHelper.desc(error)
                XLog.error(error, source: "Summary")
            }
            isSummarizing = false
        }
    }

    func save() {
        let summary = SummaryEntity(title: defaultTitle, content: summarizedResponse)
        context.insert(summary)

        do {
            try context.save()
            saved = true
        } catch {
            XLog.error(error, source: "Summary")
        }
    }

    func cancelTasks() {
        cancellationTask?.cancel()
    }
}
