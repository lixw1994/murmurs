import Foundation
import AppIntents

struct Shortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: StartRecordingIntent(), phrases: [], systemImageName: "mic.circle.fill")
    }
}
