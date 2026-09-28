import Foundation
import SwiftData
import XLog
import Observation

@MainActor @Observable final class DataContainer {
    let modelContainer: ModelContainer
    nonisolated(unsafe) let context: ModelContext

    static let shared = DataContainer()
    static let preview = DataContainer(inMemory: true)

    init(inMemory: Bool = false) {
        do {
            if inMemory {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                modelContainer = try ModelContainer(for: RecordingEntity.self, configurations: config)
            } else {
                let storeURL = URL.applicationSupportDirectory.appending(path: "WatchDataModel.sqlite")
                let config = ModelConfiguration(url: storeURL)
                modelContainer = try ModelContainer(for: RecordingEntity.self, configurations: config)
            }
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }

        context = modelContainer.mainContext
    }
}

extension DataContainer {
    func newRecordingEntity() -> RecordingEntity {
        let rec = RecordingEntity()
        context.insert(rec)
        return rec
    }

    func markRecordingAsSent(_ file: String) {
        let descriptor = FetchDescriptor<RecordingEntity>(
            predicate: #Predicate { $0.file == file }
        )
        do {
            guard let rec = try context.fetch(descriptor).first else { return }
            rec.sent = true
            try context.save()
        } catch {
            XLog.error(error, source: "DC")
        }
    }

    func deleteRecording(_ recording: RecordingEntity) {
        let fileName = recording.file
        context.delete(recording)
        do {
            try context.save()
            if let fileName {
                let url = FileHelper.fullAudioURL(for: fileName)
                XLog.debug("Delete \(fileName)", source: "DC")
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            XLog.error(error, source: "DC")
        }
    }

    func recordingsNotSent() -> [RecordingEntity] {
        let descriptor = FetchDescriptor<RecordingEntity>(
            predicate: #Predicate { $0.sent == false }
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
