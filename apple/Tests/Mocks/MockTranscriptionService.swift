import Foundation
@testable import Murmurs

class MockTranscriptionService: TranscriptionServiceProtocol {
    var transcribeAsyncResult: Result<String, Error> = .success("Mock transcription")
    var transcribeAsyncCalled = false
    var lastVoiceURL: URL?
    var lastProvider: TranscriptionProvider?
    var lastLang: TranscriptionLang?

    func transcribe(voiceURL: URL, provider: TranscriptionProvider, lang: TranscriptionLang) async throws -> String {
        transcribeAsyncCalled = true
        lastVoiceURL = voiceURL
        lastProvider = provider
        lastLang = lang
        return try transcribeAsyncResult.get()
    }

    var transcribeMemoResult: Result<String, Error> = .success("Mock transcription")
    var transcribeMemoCalled = false
    var lastTranscribedMemo: MemoEntity?

    func transcribe(_ memo: MemoEntity, completion: @escaping (Result<String, Error>) -> Void) {
        transcribeMemoCalled = true
        lastTranscribedMemo = memo
        completion(transcribeMemoResult)
    }
}
