import AVFoundation
import Speech
import XLog

class SFSpeechLiveTranscriber: LiveTranscriberProtocol {
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var continuation: AsyncStream<String>.Continuation?

    private var accumulatedText = ""
    private var currentSegmentText = ""
    private var bufferCount = 0
    private let restartThreshold = 900 // ~900 buffers at 1024 frames/16kHz ≈ ~58 seconds

    private let TAG = "LiveTrans"

    func start(lang: TranscriptionLang) -> AsyncStream<String> {
        accumulatedText = ""
        currentSegmentText = ""
        bufferCount = 0

        let localeId = lang.localeIdentifier
        if let localeId {
            recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeId))
        } else {
            recognizer = SFSpeechRecognizer()
        }

        return AsyncStream { continuation in
            self.continuation = continuation
            self.startRecognitionRequest()

            continuation.onTermination = { @Sendable _ in
                self.cancelRecognition()
            }
        }
    }

    func append(buffer: AVAudioPCMBuffer) {
        request?.append(buffer)
        bufferCount += 1

        // Auto-restart for long recordings (SFSpeechRecognizer ~1 min limit)
        if bufferCount >= restartThreshold {
            restartRecognition()
        }
    }

    func stop() async -> String {
        request?.endAudio()

        // Wait briefly for final result
        try? await Task.sleep(nanoseconds: 500_000_000)

        cancelRecognition()

        let finalText = buildFullText()
        continuation?.finish()
        continuation = nil

        XLog.info("✔︎ Live transcription final: \(finalText)", source: TAG)
        return finalText
    }

    // MARK: - Private

    private func startRecognitionRequest() {
        guard let recognizer, recognizer.isAvailable else {
            XLog.error("SFSpeechRecognizer not available", source: TAG)
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                self.currentSegmentText = result.bestTranscription.formattedString
                let fullText = self.buildFullText()
                self.continuation?.yield(fullText)

                if result.isFinal {
                    XLog.debug("⚬ segment final: \(self.currentSegmentText)", source: self.TAG)
                }
            }

            if let error {
                XLog.error("Recognition error: \(error.localizedDescription)", source: self.TAG)
            }
        }

        XLog.debug("⚬ recognition started", source: TAG)
    }

    private func restartRecognition() {
        XLog.debug("⚬ restarting recognition (buffer count: \(bufferCount))", source: TAG)

        // Save current segment text
        if !currentSegmentText.isEmpty {
            if !accumulatedText.isEmpty {
                accumulatedText += " "
            }
            accumulatedText += currentSegmentText
        }
        currentSegmentText = ""
        bufferCount = 0

        // End current request and start new one
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil

        startRecognitionRequest()
    }

    private func cancelRecognition() {
        task?.cancel()
        task = nil
        request = nil
        recognizer = nil
    }

    private func buildFullText() -> String {
        if accumulatedText.isEmpty {
            return currentSegmentText
        }
        if currentSegmentText.isEmpty {
            return accumulatedText
        }
        return accumulatedText + " " + currentSegmentText
    }
}
