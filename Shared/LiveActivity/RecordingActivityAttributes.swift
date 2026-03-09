#if os(iOS)
import ActivityKit
import Foundation

struct RecordingActivityAttributes: ActivityAttributes {
    /// Whether the recording session supports pause/resume
    let canPause: Bool

    struct ContentState: Codable, Hashable {
        let recordedTime: Int
        let isPaused: Bool
        var isFinished: Bool = false
    }
}
#endif
