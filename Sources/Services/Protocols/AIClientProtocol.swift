//
//  AIClientProtocol.swift
//  Murmurs
//

import Foundation

protocol AIClientProtocol {
    func summarize(_ msg: String, model: OpenAIChatModel, temperature: Double) async throws -> AsyncThrowingStream<String, Error>
    func polish(_ text: String, model: OpenAIChatModel) async throws -> AsyncThrowingStream<String, Error>
    func transcribe(_ fileURL: URL, lang: TranscriptionLang, model: String) async throws -> OpenAIResponse.Transcription
    func verify(_ host: String, key: String?, model: OpenAIChatModel) async throws
    func verifyWhisper(_ host: String, key: String?) async throws
}
