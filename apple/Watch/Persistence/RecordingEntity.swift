import Foundation
import SwiftData

@Model final class RecordingEntity {
    var createdAt: Date?
    var timezone: String?
    var duration: Double = 0.0
    var file: String?
    var sent: Bool = false

    init(createdAt: Date = Date(), timezone: String = TimeZone.current.identifier) {
        self.createdAt = createdAt
        self.timezone = timezone
    }
}

extension RecordingEntity {
    var viewCreatedAt: Date { createdAt ?? Date() }
    var viewTimeZone: String { timezone ?? TimeZone.current.identifier }

    var viewTitle: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: viewTimeZone)
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: createdAt ?? Date())
    }

    var viewLength: String {
        return String(format: "%02d:%02d", Int(duration) / 60, Int(duration) % 60)
    }
}
