import Foundation
import SwiftData
@testable import Murmurs

class MockMemoStore: MemoStoreProtocol {
    let context: ModelContext
    private var container: ModelContainer?

    var recordUsageCalled = false
    var recordUsageCallCount = 0
    var lastCharsSent = 0
    var lastCharsReceived = 0
    var lastWhisper = 0

    init(context: ModelContext? = nil) {
        if let context {
            self.context = context
        } else {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let c = try! ModelContainer(for: MemoEntity.self, SummaryEntity.self, PromptEntity.self, UsageEntity.self, configurations: config)
            self.container = c
            self.context = ModelContext(c)
        }
    }

    func recordUsage(charsSent: Int, charsReceived: Int, whisper: Int) {
        recordUsageCalled = true
        recordUsageCallCount += 1
        lastCharsSent = charsSent
        lastCharsReceived = charsReceived
        lastWhisper = whisper
    }
}
