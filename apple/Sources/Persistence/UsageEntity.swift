import Foundation
import SwiftData

@Model final class UsageEntity {
    var day: Int32 = 0
    var charsSent: Int32 = 0
    var charsReceived: Int32 = 0
    var whisperDuration: Int32 = 0
    var whisperCount: Int32 = 0

    init(day: Int32 = 0) {
        self.day = day
    }
}

extension UsageEntity {
    var viewDay: Int {
        if day == 0 {
            return DateHelper.todayIdentifier()
        }
        return Int(day)
    }

    var viewCharsSent: Int { Int(charsSent) }
    var viewCharsReceived: Int { Int(charsReceived) }
    var viewWisperDuration: Int { Int(whisperDuration) }
    var viewCharsTotal: Int { Int(charsSent + charsReceived) }
}
