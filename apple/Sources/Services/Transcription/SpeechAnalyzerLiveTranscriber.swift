import AVFoundation
import Speech
import XLog

@available(iOS 26, *)
class SpeechAnalyzerLiveTranscriber: LiveTranscriberProtocol {
    private var analyzer: SpeechAnalyzer?
    private var transcriber: SpeechTranscriber?
    private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    private var continuation: AsyncStream<String>.Continuation?
    private var resultTask: Task<Void, Never>?

    private var converter: AVAudioConverter?
    private var analyzerFormat: AVAudioFormat?

    private var accumulatedText = ""
    private var currentSegmentText = ""
    private let TAG = "LiveTrans.SA"

    func start(lang: TranscriptionLang) -> AsyncStream<String> {
        accumulatedText = ""
        currentSegmentText = ""

        let locale: Locale
        if let localeId = lang.localeIdentifier {
            locale = Locale(identifier: localeId)
        } else {
            locale = Locale.current
        }

        let transcriber = SpeechTranscriber(
            locale: locale,
            preset: .progressiveTranscription
        )
        self.transcriber = transcriber

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        self.analyzer = analyzer

        let (inputSequence, inputBuilder) = AsyncStream<AnalyzerInput>.makeStream()
        self.inputBuilder = inputBuilder

        return AsyncStream { continuation in
            self.continuation = continuation

            self.resultTask = Task {
                // Get the format SpeechAnalyzer expects
                if let bestFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) {
                    self.analyzerFormat = bestFormat
                    XLog.debug("⚬ analyzer format: \(bestFormat)", source: self.TAG)
                } else {
                    XLog.error("Failed to get bestAvailableAudioFormat", source: self.TAG)
                    continuation.finish()
                    return
                }

                // Start analyzer
                do {
                    try await analyzer.start(inputSequence: inputSequence)
                } catch {
                    XLog.error("Failed to start SpeechAnalyzer: \(error)", source: self.TAG)
                    continuation.finish()
                    return
                }

                // Read results
                do {
                    for try await result in transcriber.results {
                        let text = String(result.text.characters)
                        self.currentSegmentText = text
                        continuation.yield(self.buildFullText())

                        if result.isFinal {
                            XLog.debug("⚬ final: \(text)", source: self.TAG)
                            if !self.accumulatedText.isEmpty { self.accumulatedText += " " }
                            self.accumulatedText += text
                            self.currentSegmentText = ""
                        }
                    }
                } catch {
                    XLog.error("SpeechAnalyzer result error: \(error)", source: self.TAG)
                }
            }

            continuation.onTermination = { @Sendable _ in
                self.cleanup()
            }
        }
    }

    func append(buffer: AVAudioPCMBuffer) {
        guard let analyzerFormat else { return }

        // If formats match, feed directly
        if buffer.format == analyzerFormat {
            inputBuilder?.yield(AnalyzerInput(buffer: buffer))
            return
        }

        // Convert buffer to analyzer-compatible format
        if converter == nil || converter?.inputFormat != buffer.format {
            converter = AVAudioConverter(from: buffer.format, to: analyzerFormat)
        }

        guard let converter else {
            XLog.error("Failed to create audio converter for SpeechAnalyzer", source: TAG)
            return
        }

        let frameCapacity = AVAudioFrameCount(
            Double(buffer.frameLength) * analyzerFormat.sampleRate / buffer.format.sampleRate
        )
        guard frameCapacity > 0,
              let convertedBuffer = AVAudioPCMBuffer(pcmFormat: analyzerFormat, frameCapacity: frameCapacity) else {
            return
        }

        var error: NSError?
        converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        if let error {
            XLog.error("Buffer conversion error: \(error)", source: TAG)
            return
        }

        if convertedBuffer.frameLength > 0 {
            inputBuilder?.yield(AnalyzerInput(buffer: convertedBuffer))
        }
    }

    func stop() async -> String {
        inputBuilder?.finish()

        do {
            try await analyzer?.finalizeAndFinishThroughEndOfInput()
        } catch {
            XLog.error("Failed to finalize SpeechAnalyzer: \(error)", source: TAG)
        }

        // Wait for result task to finish
        await resultTask?.value

        let finalText = buildFullText()
        cleanup()

        XLog.info("✔︎ Live transcription final: \(finalText)", source: TAG)
        return finalText
    }

    private func buildFullText() -> String {
        if accumulatedText.isEmpty { return currentSegmentText }
        if currentSegmentText.isEmpty { return accumulatedText }
        return accumulatedText + " " + currentSegmentText
    }

    private func cleanup() {
        resultTask?.cancel()
        resultTask = nil
        inputBuilder = nil
        analyzer = nil
        transcriber = nil
        converter = nil
        analyzerFormat = nil
        continuation?.finish()
        continuation = nil
    }
}
