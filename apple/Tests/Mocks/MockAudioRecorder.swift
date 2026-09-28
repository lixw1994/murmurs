import Foundation
@testable import Murmurs

final class MockAudioRecorder: AudioRecorderProtocol {
    var startRecordingCalled = false
    var stopRecordingCalled = false
    var pauseRecordingCalled = false
    var resumeRecordingCalled = false
    var terminateCalled = false

    var didCompleteCallback: (() -> Void)?
    var voiceFile: URL?
    var isPaused: Bool = false

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

    func pauseRecording() {
        pauseRecordingCalled = true
        isPaused = true
    }

    func resumeRecording() {
        resumeRecordingCalled = true
        isPaused = false
    }

    func terminate() {
        terminateCalled = true
    }
}
