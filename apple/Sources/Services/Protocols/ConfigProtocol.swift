//
//  ConfigProtocol.swift
//  Murmurs
//

import Foundation

protocol ConfigProtocol: AnyObject {
    var transEnabled: Bool { get set }
    var transProvider: TranscriptionProvider { get set }
    var transLang: TranscriptionLang { get set }
    var transModel: TranscriptionModel { get set }

    var serverHost: String { get set }
    var serverAPIKey: String { get set }
    var isServerSet: Bool { get }
    var isServerValid: Bool { get }

    var sumEnabled: Bool { get set }
    var aiModel: ChatModel { get set }

    var autoSave: Bool { get set }
    var dayStartTime: Int { get set }
    var holdToRecordEnabled: Bool { get set }

    var readwiseSyncEnabled: Bool { get set }
    var readwiseToken: String { get set }
    var isReadwiseSet: Bool { get }
    var readwiseAutoSync: Bool { get set }
}
