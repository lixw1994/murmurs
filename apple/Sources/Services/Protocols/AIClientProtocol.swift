//
//  AIClientProtocol.swift
//  Murmurs
//

import Foundation

protocol AIClientProtocol {
    func summarize(_ msg: String, model: ChatModel, temperature: Double) async throws -> AsyncThrowingStream<String, Error>
    func polish(_ text: String, model: ChatModel) async throws -> AsyncThrowingStream<String, Error>
    func transcribe(_ fileURL: URL, lang: TranscriptionLang, model: String) async throws -> OpenAIResponse.Transcription
    func generateTitle(_ text: String, model: ChatModel) async throws -> String
    func verify(_ host: String, key: String?, model: ChatModel) async throws
    func verifyWhisper(_ host: String, key: String?) async throws
}
