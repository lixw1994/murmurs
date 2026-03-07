import SwiftUI
import XLog

@main
struct MurmursWatchApp: App {
    @WKApplicationDelegateAdaptor var delegate: WatchAppDelegate
    
    @State var container = DataContainer.shared
    @State var appState = WatchAppState.shared
    
    let vm: WatchViewModel
    let conn: Connectivity
    
    init() {
        #if DEBUG
        let loggerLevel = XLog.Level.debug
        #else
        let loggerLevel = XLog.Level.info
        #endif
        XLog.config(label: Bundle.main.bundleIdentifier!, level: loggerLevel)
        
        conn = Connectivity.shared
        vm = WatchViewModel.shared
        
        conn.activate()
    }
    
    var body: some Scene {
        WindowGroup {
            WatchMainView()
                .environment(vm)
                .environmentObject(conn)
                .environment(appState)
                .environment(container)
                .modelContainer(container.modelContainer)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    appState.openURL(url)
                }
        }
    }
}
