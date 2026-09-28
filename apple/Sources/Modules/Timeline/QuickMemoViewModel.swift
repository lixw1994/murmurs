import Foundation
import SwiftData
import XLog
import Observation

@MainActor @Observable final class QuickMemoViewModel {

    var content: String = ""

    private let context: ModelContext
    private let notificationCenter: NotificationCenter

    init(context: ModelContext = DataContainer.shared.context,
         notificationCenter: NotificationCenter = .default) {
        self.context = context
        self.notificationCenter = notificationCenter
    }

    func save() {
        let memo = MemoEntity(content: content)
        context.insert(memo)
        do {
            try context.save()
            notificationCenter.post(name: .memoInserted, object: memo)
        } catch {
            XLog.error(error, source: "memo")
        }
    }
}
