import Foundation
import SwiftData

@Model final class SummaryEntity {
    @Attribute(originalName: "id") var entityId: String?
    var title: String = ""
    var content: String = ""
    var createdAt: Date?
    var timezone: String?
    var prompt: String?
    var temperature: Double = 0.0
    var model: String?
    var syncedAt: Date?
    var readwiseId: String?

    init(entityId: String = UUID().uuidString.lowercased(),
         title: String = "",
         content: String = "",
         createdAt: Date = Date(),
         timezone: String = TimeZone.current.identifier) {
        self.entityId = entityId
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.timezone = timezone
    }
}

extension SummaryEntity {
    var needsSync: Bool {
        guard !content.isEmpty else { return false }
        if syncedAt == nil { return true }
        if let createdAt, let syncedAt, createdAt > syncedAt { return true }
        return false
    }

    var viewTitle: String { title }
    var viewContent: String { content }
    var shareContent: String { "# Murmurs \(viewTitle) Summary" + "\n\n" + viewContent }

    var viewCreatedAt: String {
        let formatter = DateFormatter()
        if let timezone { formatter.timeZone = TimeZone(identifier: timezone) }
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: createdAt ?? Date())
    }

    func truncatedContent(_ length: Int) -> String {
        let ret = content.prefix(length)
        if content.count > length {
            return ret + "..."
        }
        return String(ret)
    }
}

#if DEBUG
extension SummaryEntity {
    static func preview(context: ModelContext) -> SummaryEntity {
        let s = SummaryEntity(title: "2023/07/22", content: "It was a great to walk down memory lane.")
        s.timezone = "Asia/Tokyo"
        context.insert(s)
        return s
    }
}
#endif
