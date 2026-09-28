//
//  TranscriptionServiceProtocol.swift
//  Murmurs
//

import Foundation

protocol TranscriptionServiceProtocol {
    func transcribe(voiceURL: URL, provider: TranscriptionProvider, lang: TranscriptionLang) async throws -> String
    func transcribe(_ memo: MemoEntity, completion: @escaping (Result<String, Error>) -> Void)
}
