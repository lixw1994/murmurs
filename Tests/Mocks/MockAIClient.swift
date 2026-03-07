import Foundation
@testable import Murmurs

class MockAIClient: AIClientProtocol {
    var summarizeResult: [String] = ["Mock", " summary"]
    var summarizeError: Error?
    var summarizeCalled = false
    var summarizeCallCount = 0
    var lastSummarizeMsg: String?
    var lastSummarizeModel: ChatModel?
    var lastSummarizeTemperature: Double?

    func summarize(_ msg: String, model: ChatModel, temperature: Double) async throws -> AsyncThrowingStream<String, Error> {
        summarizeCalled = true
        summarizeCallCount += 1
        lastSummarizeMsg = msg
        lastSummarizeModel = model
        lastSummarizeTemperature = temperature
        if let error = summarizeError { throw error }
        return AsyncThrowingStream { continuation in
            for chunk in self.summarizeResult {
                continuation.yield(chunk)
            }
            continuation.finish()
        }
    }

    var polishResult: [String] = ["Polished", " text"]
    var polishError: Error?
    var polishCalled = false
    var lastPolishText: String?
    var lastPolishModel: ChatModel?

    func polish(_ text: String, model: ChatModel) async throws -> AsyncThrowingStream<String, Error> {
        polishCalled = true
        lastPolishText = text
        lastPolishModel = model
        if let error = polishError { throw error }
        return AsyncThrowingStream { continuation in
            for chunk in self.polishResult {
                continuation.yield(chunk)
            }
            continuation.finish()
        }
    }

    var transcribeResult: OpenAIResponse.Transcription = .init(text: "mock")
    func transcribe(_ fileURL: URL, lang: TranscriptionLang, model: String) async throws -> OpenAIResponse.Transcription {
        return transcribeResult
    }

    var verifyError: Error?
    var verifyCalled = false
    var lastVerifyHost: String?
    var lastVerifyKey: String?

    func verify(_ host: String, key: String?, model: ChatModel) async throws {
        verifyCalled = true
        lastVerifyHost = host
        lastVerifyKey = key
        if let error = verifyError { throw error }
    }

    var verifyWhisperError: Error?
    var verifyWhisperCalled = false

    func verifyWhisper(_ host: String, key: String?) async throws {
        verifyWhisperCalled = true
        if let error = verifyWhisperError { throw error }
    }
}
