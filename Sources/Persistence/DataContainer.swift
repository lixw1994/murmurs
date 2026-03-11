import Foundation
import SwiftData
import CloudKit
import XLog
import Observation

enum SyncStatus: Equatable {
    case idle
    case syncing
    case succeeded(Date)
    case failed(String)
}

@MainActor @Observable final class DataContainer: MemoStoreProtocol {
    private(set) var modelContainer: ModelContainer
    nonisolated(unsafe) var context: ModelContext
    var syncStatus: SyncStatus = .idle

    static let shared = DataContainer()
    static let preview = DataContainer(inMemory: true)

    private static let cloudKitContainerID = "iCloud.com.tangyue.murmurs"

    init(inMemory: Bool = false) {
        let container: ModelContainer
        do {
            if inMemory {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                container = try ModelContainer(
                    for: MemoEntity.self, SummaryEntity.self, PromptEntity.self, UsageEntity.self,
                    configurations: config
                )
            } else {
                container = try Self.createModelContainer(icloudEnabled: Config.shared.icloudSyncEnabled)
            }
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }

        modelContainer = container
        context = container.mainContext

        registerNotifications()

        #if DEBUG
        if inMemory {
            addPreviewData()
        }
        #endif
    }

    private static func createModelContainer(icloudEnabled: Bool) throws -> ModelContainer {
        let storeURL = URL.applicationSupportDirectory.appending(path: "DataModel.sqlite")
        let localStoreURL = URL.applicationSupportDirectory.appending(path: "LocalData.sqlite")

        let syncedConfig: ModelConfiguration
        if icloudEnabled {
            syncedConfig = ModelConfiguration(
                "CloudSync",
                url: storeURL,
                cloudKitDatabase: .private(cloudKitContainerID)
            )
        } else {
            syncedConfig = ModelConfiguration(
                "CloudSync",
                url: storeURL,
                cloudKitDatabase: .none
            )
        }

        let localConfig = ModelConfiguration(
            "LocalOnly",
            url: localStoreURL,
            cloudKitDatabase: .none
        )

        return try ModelContainer(
            for: MemoEntity.self, SummaryEntity.self, PromptEntity.self, UsageEntity.self,
            configurations: syncedConfig, localConfig
        )
    }
}

extension DataContainer {
    func reconfigureForCloudSync(enabled: Bool) {
        do {
            let container = try Self.createModelContainer(icloudEnabled: enabled)
            modelContainer = container
            context = container.mainContext
            XLog.info("Reconfigured ModelContainer, iCloud sync: \(enabled)", source: "DC")
        } catch {
            XLog.error("Failed to reconfigure ModelContainer: \(error.localizedDescription)", source: "DC")
        }
    }

    func addMemo(content: String) {
        let memo = MemoEntity(content: content)
        context.insert(memo)
        do {
            try context.save()
        } catch {
            XLog.error("failed to add memo: \(error.localizedDescription)")
        }
    }

    /// Populate audioData from local file when audio sync is enabled
    func populateAudioDataIfNeeded(_ memo: MemoEntity) {
        guard Config.shared.icloudSyncEnabled, Config.shared.icloudSyncAudio else { return }
        guard let file = memo.file, memo.audioData == nil else { return }
        let url = FileHelper.fullAudioURL(for: file)
        guard FileManager.default.fileExists(atPath: url.path()) else { return }
        do {
            memo.audioData = try Data(contentsOf: url)
            XLog.info("Populated audioData for memo \(memo.entityId)", source: "DC")
        } catch {
            XLog.error("Failed to read audio file: \(error)", source: "DC")
        }
    }

    /// Restore local audio file from synced audioData
    func restoreAudioFileIfNeeded(_ memo: MemoEntity) {
        guard let file = memo.file, let audioData = memo.audioData else { return }
        let url = FileHelper.fullAudioURL(for: file)
        guard !FileManager.default.fileExists(atPath: url.path()) else { return }
        do {
            let dir = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try audioData.write(to: url)
            XLog.info("Restored audio file for memo \(memo.entityId)", source: "DC")
        } catch {
            XLog.error("Failed to restore audio file: \(error)", source: "DC")
        }
    }

    /// Clear audioData when audio sync is disabled
    func clearAudioDataIfNeeded(_ memo: MemoEntity) {
        guard !Config.shared.icloudSyncAudio, memo.audioData != nil else { return }
        memo.audioData = nil
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
