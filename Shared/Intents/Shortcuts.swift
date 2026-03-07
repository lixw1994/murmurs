import Foundation
import AppIntents

struct Shortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartRecordingIntent(),
            phrases: [
                "Record with \(.applicationName)",
                "Start recording in \(.applicationName)",
                "\(.applicationName)开始录音",
                "用\(.applicationName)录音",
            ],
            shortTitle: LocalizedStringResource(stringLiteral: "start_recording"),
            systemImageName: "mic.circle.fill"
        )
    }
}
