import SwiftUI
import ActivityKit

@main
struct MurmursApp: App {
    @UIApplicationDelegateAdaptor var delegate: AppDelegate

    let container = DataContainer.shared
    let appState = AppState.shared
    let conn = Connectivity.shared
    let accountService = AccountService.shared

    @Environment(\.scenePhase) private var scenePhase

    @StateObject var config = Config.shared
    @AppStorage("dark_mode") var darkMode = DarkMode.auto

    init() {
        // Clean up any orphaned Live Activities from a previous crash
        for activity in Activity<RecordingActivityAttributes>.activities {
            Task { await activity.end(dismissalPolicy: .immediate) }
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .tint(Color.app_accent)
                .environment(container)
                .environment(appState)
                .environment(accountService)
                .environmentObject(config)
                .environmentObject(conn)
                .modelContainer(container.modelContainer)
                .preferredColorScheme(darkMode.colorScheme)
                .onOpenURL { url in
                    appState.openURL(url)
                }
                .onChange(of: scenePhase, initial: true) { _, phase in
                    // Create or restore the anonymous account in the background (adr/0015).
                    guard phase == .active, AccountService.isAutomaticSetupEnabled else { return }
                    Task { await accountService.ensureAccount() }
                }
        }
    }
}
