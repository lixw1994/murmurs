import Foundation
import SwiftData
import XLog

@Model final class MemoEntity {
    @Attribute(originalName: "id") var entityId: String = ""
    var content: String?
    var createdAt: Date?
    var timezone: String = ""
    var day: Int32 = 0
    var file: String?
    var duration: Double = 0.0
    var transcribed: Bool = false
    var isFromWatch: Bool = false
    var isHidden: Bool = false
    var journal: Int32 = 0
    var syncedAt: Date?
    var updatedAt: Date?
    var readwiseId: String?
    var polishedContent: String?

    init(entityId: String = UUID().uuidString.lowercased(),
         content: String? = nil,
         createdAt: Date = Date(),
         timezone: String = TimeZone.current.identifier,
         day: Int32 = Int32(DateHelper.todayIdentifier()),
         file: String? = nil,
         duration: Double = 0.0) {
        self.entityId = entityId
        self.content = content
        self.createdAt = createdAt
        self.timezone = timezone
        self.day = day
        self.file = file
        self.duration = duration
    }
}

// MARK: - Computed Properties

extension MemoEntity {
    var viewContent: String {
        content ?? ""
    }

    var viewPolishedContent: String {
        polishedContent ?? ""
    }

    var hasPolishedContent: Bool {
        polishedContent != nil && !polishedContent!.isEmpty
    }

    /// Returns polished content if available, otherwise original content
    var displayContent: String {
        hasPolishedContent ? viewPolishedContent : viewContent
    }

    var viewCreatedAt: String {
        let formatter = DateFormatter()
        if !timezone.isEmpty { formatter.timeZone = TimeZone(identifier: timezone) }
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: createdAt ?? Date())
    }

    var viewTime: String {
        let formatter = DateFormatter()
        if !timezone.isEmpty { formatter.timeZone = TimeZone(identifier: timezone) }
        formatter.dateFormat = "H:mm"
        return formatter.string(from: createdAt ?? Date())
    }

    var needsTranscription: Bool {
        guard file != nil else { return false }
        if isFromWatch { return true }
        if Config.shared.transEnabled && Config.shared.autoSave && !transcribed {
            return true
        }
        return false
    }

    var needsSync: Bool {
        guard content != nil, !content!.isEmpty else { return false }
        guard !isHidden else { return false }
        if syncedAt == nil { return true }
        if let updatedAt, let syncedAt, updatedAt > syncedAt { return true }
        return false
    }

    func updateCreationTime(_ time: Date) {
        guard createdAt != time else { return }
        createdAt = time
        timezone = TimeZone.current.identifier
        day = Int32(DateHelper.identifier(from: time.realDate))
    }
}

// MARK: - Static Helpers

extension MemoEntity {
    static func delete(context: ModelContext, memo: MemoEntity) {
        if let file = memo.file {
            let url = FileHelper.fullAudioURL(for: file)
            do {
                XLog.debug("Deleting audio file at \(url.absoluteString)", source: "memo")
                try FileManager.default.removeItem(at: url)
            } catch {
                XLog.error(error, source: "memo")
            }
        }

        do {
            XLog.debug("Deleting memo \(memo.entityId)", source: "memo")
            context.delete(memo)
            try context.save()
        } catch {
            XLog.error(error, source: "memo")
        }
    }

    static func deleteMemos(context: ModelContext, memos: Set<MemoEntity>) {
        var filesToDelete = [URL]()
        for memo in memos {
            if let file = memo.file {
                filesToDelete.append(FileHelper.fullAudioURL(for: file))
            }
            context.delete(memo)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            do {
                try context.save()
                for url in filesToDelete {
                    try? FileManager.default.removeItem(at: url)
                }
                XLog.debug("Successfully deleted \(memos.count) memos", source: "memo")
            } catch {
                XLog.error("Failed to save after deletion: \(error)", source: "memo")
            }
        }
    }
}

#if DEBUG
extension MemoEntity {
    static func preview(context: ModelContext) -> MemoEntity {
        let memo = MemoEntity(content: "I went to the movies today with my friends.")
        memo.timezone = "Asia/Tokyo"
        context.insert(memo)
        return memo
    }
}
#endif
