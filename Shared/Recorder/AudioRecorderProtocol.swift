//
//  AudioRecorderProtocol.swift
//  Murmurs
//

import Foundation

protocol AudioRecorderProtocol: AnyObject {
    func startRecording()
    func stopRecording()
    func pauseRecording()
    func resumeRecording()
    func terminate()
    var didCompleteCallback: (() -> Void)? { get set }
    var voiceFile: URL? { get set }
    var isPaused: Bool { get }
}
