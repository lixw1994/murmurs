import Foundation
import SwiftData
import XLog

extension DataContainer {
    func getTodayUsage() -> UsageEntity {
        let day = Int32(DateHelper.todayIdentifier())
        let descriptor = FetchDescriptor<UsageEntity>(
            predicate: #Predicate { $0.day == day }
        )

        if let exist = try? context.fetch(descriptor).first {
            return exist
        }

        let usage = UsageEntity(day: day)
        context.insert(usage)
        return usage
    }

    func recordUsage(charsSent: Int = 0, charsReceived: Int = 0, whisper: Int = 0) {
        guard charsSent >= 0 && charsReceived >= 0 && whisper >= 0 else { return }

        XLog.debug("Record usage: sent: \(charsSent), received: \(charsReceived), whisper: \(whisper)", source: "Usage")

        let usage = getTodayUsage()
        usage.charsSent += Int32(charsSent)
        usage.charsReceived += Int32(charsReceived)
        usage.whisperDuration += Int32(whisper)
        try? context.save()
    }
}
