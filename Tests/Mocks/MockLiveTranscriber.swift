import AVFoundation
@testable import Murmurs

class MockLiveTranscriber: LiveTranscriberProtocol {
    var startCalled = false
    var appendCalled = false
    var stopCalled = false
    var lastLang: TranscriptionLang?
    var appendedBuffers: [AVAudioPCMBuffer] = []

    var streamTexts: [String] = ["Hello"]
    var finalText = "Hello world"

    func start(lang: TranscriptionLang) -> AsyncStream<String> {
        startCalled = true
        lastLang = lang
        return AsyncStream { continuation in
            for text in streamTexts {
                continuation.yield(text)
            }
            continuation.finish()
        }
    }

    func append(buffer: AVAudioPCMBuffer) {
        appendCalled = true
        appendedBuffers.append(buffer)
    }

    func stop() async -> String {
        stopCalled = true
        return finalText
    }
}
