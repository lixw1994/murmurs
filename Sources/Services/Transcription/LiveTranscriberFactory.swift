import Foundation

enum LiveTranscriberFactory {
    static func create() -> LiveTranscriberProtocol {
        if #available(iOS 26, *) {
            return SpeechAnalyzerLiveTranscriber()
        } else {
            return SFSpeechLiveTranscriber()
        }
    }
}
