import SwiftUI
import XLog

struct WatchRecordView: View {
    @StateObject var recorder = AudioRecorder()
    @Environment(DataContainer.self) var dc
    @Environment(WatchAppState.self) var appState
    @EnvironmentObject var conn: Connectivity
    @Environment(WatchViewModel.self) var vm
    
    var body: some View {
        @Bindable var appState = appState
        NavigationView {
            ZStack {
                Color.watch_bg
                recordButton
            }.task {
                appState.checkMicPermission()
            }
            .alert(L(.watch_permission_title), isPresented: $appState.showPermissionAlert) {
            } message: {
                Text(L(.watch_permission_msg))
            }
            .onChange(of: recorder.isCompleted) { oldValue, newValue in
                if newValue {
                    vm.saveFile(recorder.voiceFile!)
                }
                resetRecorder()
            }
            .fullScreenCover(isPresented: $appState.showRecording) {
                WatchRecordingView(recorder: recorder)
                    .interactiveDismissDisabled()
            }
        }
    }
    
    private var recordButton: some View {
        Button {
            withoutAnimation {
                appState.startRecording()
            }
        } label: {
            Circle()
                .fill(.red)
                .frame(width: 50)
                .padding()
                .background(Color.watch_rec_btn_border)
        }
        .clipShape(Circle())
        .buttonStyle(.borderless)
        .animation(.default, value: recorder.isRecording)
    }
    
    private func resetRecorder() {
        recorder.isCompleted = false
    }
    
    private func withoutAnimation(action: @escaping () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            action()
        }
    }
    
}

#Preview {
    WatchRecordView()
        .environment(WatchAppState.shared)
}
