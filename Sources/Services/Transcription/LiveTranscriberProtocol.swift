import AVFoundation

protocol LiveTranscriberProtocol {
    /// Start live transcription, returns an async stream of progressive transcription text
    func start(lang: TranscriptionLang) -> AsyncStream<String>
    /// Feed audio buffer from AVAudioEngine tap
    func append(buffer: AVAudioPCMBuffer)
    /// Stop transcription and return final accumulated text
    func stop() async -> String
}
