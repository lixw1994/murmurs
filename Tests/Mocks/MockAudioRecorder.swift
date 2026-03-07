import Foundation
@testable import Murmurs

final class MockAudioRecorder: AudioRecorderProtocol {
    var startRecordingCalled = false
    var stopRecordingCalled = false
    var terminateCalled = false

    var didCompleteCallback: (() -> Void)?
    var voiceFile: URL?

    var simulateSuccessfulRecording = true

    func startRecording() {
        startRecordingCalled = true
    }

    func stopRecording() {
        stopRecordingCalled = true
        if simulateSuccessfulRecording {
            didCompleteCallback?()
        }
    }

    func terminate() {
        terminateCalled = true
    }
}
