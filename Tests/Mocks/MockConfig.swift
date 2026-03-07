import Foundation
@testable import Murmurs

final class MockConfig: ConfigProtocol {
    var transEnabled: Bool = false
    var transProvider: TranscriptionProvider = .apple
    var transLang: TranscriptionLang = .auto
    var transModel: TranscriptionModel = .whisper_1

    var serverHost: String = ""
    var serverAPIKey: String = ""
    var isServerSet: Bool = false
    var isServerValid: Bool = false

    var sumEnabled: Bool = false
    var aiModel: OpenAIChatModel = .gpt_3_5

    var autoSave: Bool = true
    var dayStartTime: Int = 2
    var holdToRecordEnabled: Bool = false

    var readwiseSyncEnabled: Bool = false
    var readwiseToken: String = ""
    var isReadwiseSet: Bool { readwiseSyncEnabled && !readwiseToken.isEmpty }
    var readwiseAutoSync: Bool = false
}
