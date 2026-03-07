import Foundation
import AVFoundation
import Observation
import XLog

@MainActor @Observable final class RecordingViewModel {
    var liveTranscriptionText = ""
    var isLiveTranscribing = false

    private var liveTranscriber: LiveTranscriberProtocol?
    private var transcriptionTask: Task<Void, Never>?

    private let config: any ConfigProtocol

    /// Whether live transcription should be active for this recording session
    var shouldUseLiveTranscription: Bool {
        config.transEnabled && config.transProvider == .apple
    }

    init(config: any ConfigProtocol = Config.shared) {
        self.config = config
    }

    deinit {
        #if DEBUG
            XLog.debug("✖︎ RecordingViewModel", source: "Recording")
        #endif
    }

    /// Configure the recorder for engine mode if live transcription is active
    func configureRecorder(_ recorder: AudioRecorder) {
        guard shouldUseLiveTranscription else { return }

        let transcriber = LiveTranscriberFactory.create()
        self.liveTranscriber = transcriber

        recorder.onBufferCaptured = { [weak self] buffer in
            transcriber.append(buffer: buffer)
        }
    }

    /// Start listening for live transcription results
    func startLiveTranscription() {
        guard let transcriber = liveTranscriber else { return }

        isLiveTranscribing = true
        let stream = transcriber.start(lang: config.transLang)

        transcriptionTask = Task { @MainActor in
            for await text in stream {
                self.liveTranscriptionText = text
            }
        }

        XLog.info("Live transcription started", source: "Recording")
    }

    /// Stop live transcription and return final text
    func stopLiveTranscription() async -> String? {
        guard let transcriber = liveTranscriber else { return nil }

        let finalText = await transcriber.stop()
        transcriptionTask?.cancel()
        transcriptionTask = nil
        isLiveTranscribing = false
        liveTranscriber = nil

        XLog.info("Live transcription stopped, text length: \(finalText.count)", source: "Recording")
        return finalText.isEmpty ? nil : finalText
    }
}
