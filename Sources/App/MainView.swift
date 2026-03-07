import SwiftUI

struct MainView: View {
    @Environment(DataContainer.self) var container
    @EnvironmentObject var config: Config
    @Environment(AppState.self) var appState

    var body: some View {
        @Bindable var appState = appState
        TabView(selection: $appState.activeTab) {
            TimelineView()
                .tabItem {
                    Image("tab_timeline")
                    Text(L(.timeline))
                }
                .tag(0)
                .toolbar(config.sumEnabled ? .visible : .hidden, for: .tabBar)
            
            SummaryView()
                .tabItem {
                    Image("tab_summary")
                    Text(L(.summary))
                }
                .tag(1)
        }
        .sheet(item: $appState.activeSheet) { item in
            switch item {
            case .settings:
                SettingsView()
            case .quickMemo:
                QuickMemoView()
            case .summarize(let item):
                AddSummaryPromptView(item: item)
                    .interactiveDismissDisabled()
            case .micPermission:
                MicPermissionView()
            case .editMemo(let memo):
                MemoEditView(memo: memo)
            case .editSummary(let summary):
                SummaryEditView(summary: summary)
            }
        }
        .sheet(isPresented: $appState.showRecording) {
            RecordingView()
        }
    }
}

#if DEBUG
#Preview {
    MainView()
        .environment(AppState.shared)
}
#endif
