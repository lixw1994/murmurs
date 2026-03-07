//
//  AudioRecorderProtocol.swift
//  Murmurs
//

import Foundation

protocol AudioRecorderProtocol: AnyObject {
    func startRecording()
    func stopRecording()
    func terminate()
    var didCompleteCallback: (() -> Void)? { get set }
    var voiceFile: URL? { get set }
}
