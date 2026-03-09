#if os(iOS)
import AppIntents
import Foundation

struct TogglePauseRecordingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Toggle Pause Recording"

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NotificationCenter.default.post(name: .togglePauseRecording, object: nil)
        }
        return .result()
    }
}

struct StopRecordingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Recording"

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NotificationCenter.default.post(name: .stopRecording, object: nil)
        }
        return .result()
    }
}
#endif
