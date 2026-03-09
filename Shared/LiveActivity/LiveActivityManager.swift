#if os(iOS)
import ActivityKit
import Foundation
import XLog

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<RecordingActivityAttributes>?

    private init() {}

    func startActivity(canPause: Bool) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            XLog.info("Live Activities not enabled", source: "LiveActivity")
            return
        }

        let attributes = RecordingActivityAttributes(canPause: canPause)
        let initialState = RecordingActivityAttributes.ContentState(
            recordedTime: 0,
            isPaused: false
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            XLog.info("Live Activity started: \(activity.id)", source: "LiveActivity")
        } catch {
            XLog.error("Failed to start Live Activity: \(error)", source: "LiveActivity")
        }
    }

    func updateActivity(recordedTime: Int, isPaused: Bool) {
        guard let activity = currentActivity else { return }

        let state = RecordingActivityAttributes.ContentState(
            recordedTime: recordedTime,
            isPaused: isPaused
        )

        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    func endActivity(dismissed: Bool, finalTime: Int = 0) {
        guard let activity = currentActivity else { return }

        let finalState = RecordingActivityAttributes.ContentState(
            recordedTime: finalTime,
            isPaused: false,
            isFinished: !dismissed
        )

        Task {
            await activity.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: dismissed ? .immediate : .after(.now + 2)
            )
            XLog.info("Live Activity ended (dismissed: \(dismissed))", source: "LiveActivity")
        }

        currentActivity = nil
    }
}
#endif
