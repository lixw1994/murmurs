import Foundation
import AppIntents

struct StartRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource(stringLiteral: "start_recording")
    static var description: IntentDescription = IntentDescription(LocalizedStringResource(stringLiteral: "start_recording_description"))

    @MainActor
    func perform() async throws -> some IntentResult {
        #if os(iOS)
            AppState.shared.startRecording()
        #else
            WatchAppState.shared.startRecording()
        #endif
        return .result()
    }
  
    static var openAppWhenRun: Bool = true
}
