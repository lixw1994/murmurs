import Foundation
import SwiftData
import XLog
import Observation

@MainActor @Observable final class QuickMemoViewModel {

    var content: String = ""

    private let context: ModelContext

    init(context: ModelContext = DataContainer.shared.context) {
        self.context = context
    }

    func save() {
        let memo = MemoEntity(content: content)
        context.insert(memo)
        do {
            try context.save()
            NotificationCenter.default.post(name: .memoInserted, object: memo)
        } catch {
            XLog.error(error, source: "memo")
        }
    }
}
