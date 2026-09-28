import Foundation
import AVFoundation
import XLog

class FileHelper {
    static let AUDIO_FOLDER = "audio"
    
    static func moveAudioFile(_ srcURL: URL) throws -> URL {
        let fs = FileManager.default
        let audioDirURL = URL.documentsDirectory.appendingPathComponent(AUDIO_FOLDER)
        
        if !fs.fileExists(atPath: audioDirURL.path()) {
            XLog.info("Creating audio folder at \(audioDirURL)", source: "FileHelper")
            try fs.createDirectory(at: audioDirURL, withIntermediateDirectories: true)
        }
        
        let fileName = srcURL.lastPathComponent
        let destURL = fullAudioURL(for: fileName)
        
        XLog.info("Moving \(fileName) to audio folder", source: "FileHelper")
        try fs.moveItem(at: srcURL, to: destURL)
        
        return destURL
    }
    
    static func getAudioDuration(_ url: URL) async -> Double {
        let audioAsset = AVURLAsset.init(url: url, options: nil)
        do {
            let duration = try await audioAsset.load(.duration)
            return CMTimeGetSeconds(duration)
        } catch {
            XLog.error("Failed to get audio duration with \(error)", source: "FileHelper")
            return 0
        }
    }
    
    static func fullAudioURL(for fileName: String) -> URL {
        let audioDirURL = URL.documentsDirectory.appendingPathComponent(AUDIO_FOLDER)
        return audioDirURL.appending(path: fileName)
    }

    #if os(iOS)
    static func mergeAudioFiles(original: URL, append: URL) async throws -> URL {
        let composition = AVMutableComposition()
        guard let track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw NSError(domain: "FileHelper", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create composition track"])
        }

        let originalAsset = AVURLAsset(url: original)
        let appendAsset = AVURLAsset(url: append)

        let originalDuration = try await originalAsset.load(.duration)
        let appendDuration = try await appendAsset.load(.duration)

        guard let originalTrack = try await originalAsset.loadTracks(withMediaType: .audio).first else {
            throw NSError(domain: "FileHelper", code: 2, userInfo: [NSLocalizedDescriptionKey: "No audio track in original file"])
        }
        guard let appendTrack = try await appendAsset.loadTracks(withMediaType: .audio).first else {
            throw NSError(domain: "FileHelper", code: 3, userInfo: [NSLocalizedDescriptionKey: "No audio track in append file"])
        }

        try track.insertTimeRange(CMTimeRange(start: .zero, duration: originalDuration), of: originalTrack, at: .zero)
        try track.insertTimeRange(CMTimeRange(start: .zero, duration: appendDuration), of: appendTrack, at: originalDuration)

        let outputURL = URL(filePath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString.lowercased() + ".m4a")

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "FileHelper", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"])
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a

        await exportSession.export()

        guard exportSession.status == .completed else {
            throw exportSession.error ?? NSError(domain: "FileHelper", code: 5, userInfo: [NSLocalizedDescriptionKey: "Audio export failed"])
        }

        // Clean up the append temp file
        try? FileManager.default.removeItem(at: append)

        XLog.info("Merged audio files → \(outputURL.lastPathComponent)", source: "FileHelper")
        return outputURL
    }
    #endif
}
