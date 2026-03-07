import Foundation
import AVFoundation
import WatchKit
import Observation

@Observable final class WatchAppState {
    static let shared = WatchAppState()
    private init() {}

    var micPermission: AVAudioSession.RecordPermission = .undetermined
    var showRecording = false
    var showPermissionAlert = false
    
    func checkMicPermission() {
        micPermission = AVAudioSession.sharedInstance().recordPermission
    }
    
    func startRecording() {
        guard showRecording == false else { return }
        WKInterfaceDevice.current().play(.start)
        guard micPermission != .denied else {
            showPermissionAlert = true
            return
        }
        AudioPlayer.shared.stop()
        showRecording = true
    }
    
    func openURL(_ url: URL) {
        guard let host = url.host() else { return }
        switch host {
        case "record":
            startRecording()
        default: return
        }
    }
}
