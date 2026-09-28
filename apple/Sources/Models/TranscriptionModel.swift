import Foundation

enum TranscriptionModel: String, CaseIterable {
    case whisper_1
    case gpt_4o_mini_transcribe
    case gpt_4o_transcribe
    
    var displayName: String {
        switch self {
        case .whisper_1: return "Whisper-1"
        case .gpt_4o_mini_transcribe: return "GPT-4o mini"
        case .gpt_4o_transcribe: return "GPT-4o"
        }
    }
    
    var name: String {
        switch self {
        case .whisper_1: return "whisper-1"
        case .gpt_4o_mini_transcribe: return "gpt-4o-mini-transcribe"
        case .gpt_4o_transcribe: return "gpt-4o-transcribe"
        }
    }
    
}
