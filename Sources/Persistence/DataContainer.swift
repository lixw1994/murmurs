import Foundation
import SwiftData
import XLog
import Observation

@MainActor @Observable final class DataContainer: MemoStoreProtocol {
    let modelContainer: ModelContainer
    nonisolated(unsafe) let context: ModelContext

    static let shared = DataContainer()
    static let preview = DataContainer(inMemory: true)

    init(inMemory: Bool = false) {
        do {
            if inMemory {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                modelContainer = try ModelContainer(
                    for: MemoEntity.self, SummaryEntity.self, PromptEntity.self, UsageEntity.self,
                    configurations: config
                )
            } else {
                let storeURL = URL.applicationSupportDirectory.appending(path: "DataModel.sqlite")
                let config = ModelConfiguration(url: storeURL)
                modelContainer = try ModelContainer(
                    for: MemoEntity.self, SummaryEntity.self, PromptEntity.self, UsageEntity.self,
                    configurations: config
                )
            }
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }

        context = modelContainer.mainContext

        registerNotifications()

        #if DEBUG
        if inMemory {
            addPreviewData()
        }
        #endif
    }
}

extension DataContainer {
    func addMemo(content: String) {
        let memo = MemoEntity(content: content)
        context.insert(memo)
        do {
            try context.save()
        } catch {
            XLog.error("failed to add memo: \(error.localizedDescription)")
        }
    }

    func deleteMemo(_ entity: MemoEntity) {
        context.delete(entity)
        do {
            try context.save()
        } catch {
            XLog.error("failed to delete memo: \(error.localizedDescription)")
        }
    }
}
