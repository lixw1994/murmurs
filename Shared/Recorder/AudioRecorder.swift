import Foundation
import XLog
import AVFoundation

class AudioRecorder: NSObject, ObservableObject, AudioRecorderProtocol {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var isCompleted = false
    @Published var recordedTime: Int = 0
    @Published var voiceFile: URL?
    @Published var samples: [Float] = []

    var didFinishCallback: (() -> Void)?
    var didCompleteCallback: (() -> Void)?

    private var recorder: AVAudioRecorder?
    private var session: AVAudioSession!
    private var timer: Timer?

    private var isTerminating = false

    // MARK: - Engine mode (iOS only)

    #if os(iOS)
    /// Set this before calling startRecording() to use AVAudioEngine mode.
    /// Each captured buffer will be passed to this callback.
    var onBufferCaptured: ((AVAudioPCMBuffer) -> Void)?

    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var engineStartTime: Date?
    private var engineCurrentLevel: Float = 0
    private var useEngineMode: Bool { onBufferCaptured != nil }
    #endif

    var canPause: Bool {
        #if os(iOS)
        return !useEngineMode
        #else
        return true
        #endif
    }

    var formattedTime: String {
        String(format: "%02d:%02d", recordedTime / 60, recordedTime % 60)
    }

    // MARK: - Session Prewarming

    private static var prewarmTask: Task<Void, Never>?
    private static var sessionPrewarmed = false

    /// Call early (e.g. when user taps record button) to start configuring
    /// AVAudioSession in parallel with UI animations. The slow part is
    /// Bluetooth route negotiation which can take 0-3 seconds.
    static func prewarmSession() {
        guard prewarmTask == nil else { return }
        sessionPrewarmed = false
        prewarmTask = Task.detached {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setAllowHapticsAndSystemSoundsDuringRecording(true)
                #if os(iOS)
                try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.duckOthers, .allowBluetooth])
                #else
                try session.setCategory(.playAndRecord, mode: .default, options: .duckOthers)
                #endif
                try session.setActive(true)
                AudioRecorder.sessionPrewarmed = true
                XLog.debug("Audio session prewarmed", source: "Audio")
            } catch {
                XLog.error("Prewarm failed: \(error)", source: "Audio")
            }
        }
    }

    /// Await completion of a previously started prewarm. Returns immediately
    /// if no prewarm is in progress.
    static func awaitPrewarm() async {
        await prewarmTask?.value
        prewarmTask = nil
    }

    deinit {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)

        #if DEBUG
            XLog.debug("✖︎ Audio Recorder", source: "Audio")
        #endif
    }

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
    }

    @objc private func handleInterruption(notification: Notification) {
        if let info = notification.userInfo,
            let typeInt = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeInt) {
            if type == .began && isRecording {
                stopRecording()
            }
        }
    }

    func pauseRecording() {
        #if os(iOS)
        guard !useEngineMode else { return }
        #endif
        guard isRecording, !isPaused, let recorder else { return }
        recorder.pause()
        isPaused = true
        stopMonitoring()
        XLog.debug("Recording paused", source: "Audio")
    }

    func resumeRecording() {
        #if os(iOS)
        guard !useEngineMode else { return }
        #endif
        guard isRecording, isPaused, let recorder else { return }
        recorder.record()
        isPaused = false
        startMonitoring()
        XLog.debug("Recording resumed", source: "Audio")
    }

    func startRecording() {
        guard isRecording == false else {
            return
        }
        self.isTerminating = false
        requestPermissionAndStartRecording()
    }

    func stopRecording() {
        XLog.debug("stop recording", source: "Audio")

        #if os(iOS)
        if useEngineMode {
            guard audioEngine != nil, isRecording else { return }
            stopEngineRecording()
            return
        }
        #endif

        guard recorder != nil, isRecording else {
            return
        }

        isPaused = false
        recorder?.stop()

        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setMode(.default)
    }

    func terminate() {
        XLog.debug("terminating recording", source: "Audio")
        guard isRecording else { return }
        self.isTerminating = true
        self.isPaused = false

        #if os(iOS)
        if useEngineMode {
            stopEngineRecording()
            // Delete temporary files
            if let url = voiceFile {
                try? FileManager.default.removeItem(at: url)
            }
            return
        }
        #endif

        stopRecording()
        recorder?.deleteRecording()
    }

    static func requestPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission() { allowed in
            DispatchQueue.main.async {
                #if os(iOS)
                AppState.shared.micPermission = AVAudioSession.sharedInstance().recordPermission
                #else
                WatchAppState.shared.micPermission = AVAudioSession.sharedInstance().recordPermission
                #endif
            }
        }
    }

    private func requestPermissionAndStartRecording() {
        do {
            session = AVAudioSession.sharedInstance()
            if !AudioRecorder.sessionPrewarmed {
                try session.setAllowHapticsAndSystemSoundsDuringRecording(true)
                #if os(iOS)
                try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.duckOthers, .allowBluetooth])
                #else
                try session.setCategory(.playAndRecord, mode: .default, options: .duckOthers)
                #endif
                try session.setActive(true)
            }
            AudioRecorder.sessionPrewarmed = false
            session.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    #if os(iOS)
                    AppState.shared.micPermission = AVAudioSession.sharedInstance().recordPermission
                    #else
                    WatchAppState.shared.micPermission = AVAudioSession.sharedInstance().recordPermission
                    #endif
                    if allowed {
                        #if os(iOS)
                        if self.useEngineMode {
                            self.recordWithEngine()
                        } else {
                            self.record()
                        }
                        #else
                        self.record()
                        #endif
                    }
                }
            }
        } catch {
            XLog.error(error)
        }
    }

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { timer in
            #if os(iOS)
            if self.useEngineMode {
                if let startTime = self.engineStartTime {
                    self.recordedTime = Int(Date().timeIntervalSince(startTime))
                }
                let level = self.engineCurrentLevel
                self.samples += [level, level, level]
                return
            }
            #endif

            guard let recorder = self.recorder else { return }
            self.recordedTime = Int(recorder.currentTime)

            #if os(iOS)
            recorder.updateMeters()
            let power = recorder.averagePower(forChannel: 0)
            let linear = max(0, min(1, (power + 50) / 50))
            self.samples += [linear, linear, linear]
            #endif
        })
        // Ensure timer fires during UI interactions (e.g. scrolling)
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }

    private func stopMonitoring() {
        timer?.invalidate()
    }

    private func record() {
        let url = tmpFileURL()
        XLog.debug("Save audio file to \(url.absoluteString)", source: "Audio")

        let settings = [
           AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
           AVSampleRateKey: 24000,
           AVNumberOfChannelsKey: 1,
           AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]

        do {
            let rec = try AVAudioRecorder(url: url, settings: settings)
            rec.delegate = self
            rec.isMeteringEnabled = true
            rec.prepareToRecord()
            rec.record()
            recorder = rec
            isRecording = true
            startMonitoring()
        } catch {
            XLog.error("Failed to start audio engine: \(error.localizedDescription)")
        }
    }

    #if os(iOS)
    private func recordWithEngine() {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Validate format - inputNode may return invalid format before audio session is ready
        guard inputFormat.channelCount > 0, inputFormat.sampleRate > 0 else {
            XLog.error("Invalid input format: channels=\(inputFormat.channelCount) sampleRate=\(inputFormat.sampleRate), falling back to AVAudioRecorder", source: "Audio")
            onBufferCaptured = nil
            record()
            return
        }

        // Create temporary PCM file for recording
        let pcmURL = tmpFileURL(ext: "caf")
        XLog.debug("Engine mode: save PCM to \(pcmURL.absoluteString), format: \(inputFormat)", source: "Audio")

        do {
            audioFile = try AVAudioFile(forWriting: pcmURL, settings: inputFormat.settings)
        } catch {
            XLog.error("Failed to create audio file: \(error.localizedDescription), falling back to AVAudioRecorder", source: "Audio")
            onBufferCaptured = nil
            record()
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, time in
            guard let self else { return }

            // Write to file
            do {
                try self.audioFile?.write(from: buffer)
            } catch {
                XLog.error("Failed to write audio buffer: \(error.localizedDescription)", source: "Audio")
            }

            // Feed buffer to live transcriber
            self.onBufferCaptured?(buffer)

            // Calculate audio level for waveform (read by timer on main thread)
            // Use RMS → dB → normalize to 0…1 with -50 dB floor
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            var sumOfSquares: Float = 0
            for i in 0..<frameLength {
                let sample = channelData[i]
                sumOfSquares += sample * sample
            }
            let rms = sqrt(sumOfSquares / Float(frameLength))
            let avgPower: Float = rms > 0 ? 20 * log10(rms) : -50
            self.engineCurrentLevel = max(0, min(1, (avgPower + 50) / 50))
        }

        do {
            engine.prepare()
            try engine.start()
            self.audioEngine = engine
            self.engineStartTime = Date()
            isRecording = true
            startMonitoring()
            XLog.info("Engine mode recording started", source: "Audio")
        } catch {
            XLog.error("Failed to start AVAudioEngine: \(error.localizedDescription)", source: "Audio")
        }
    }

    private func stopEngineRecording() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioFile = nil
        engineStartTime = nil
        stopMonitoring()

        if !isTerminating {
            // Convert PCM (caf) to M4A (aac)
            let pcmFiles = findTmpFiles(ext: "caf")
            guard let pcmURL = pcmFiles.last else {
                XLog.error("No PCM file found after engine recording", source: "Audio")
                isRecording = false
                return
            }

            let m4aURL = tmpFileURL()
            convertToM4A(from: pcmURL, to: m4aURL) { [weak self] success in
                guard let self else { return }
                // Clean up PCM file
                try? FileManager.default.removeItem(at: pcmURL)

                DispatchQueue.main.async {
                    if success {
                        self.voiceFile = m4aURL
                        self.isCompleted = true
                        self.didCompleteCallback?()
                    }
                    self.didFinishCallback?()
                    self.isRecording = false
                }
            }
        } else {
            // Clean up PCM files
            for url in findTmpFiles(ext: "caf") {
                try? FileManager.default.removeItem(at: url)
            }
            didFinishCallback?()
            isRecording = false
        }

        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setMode(.default)
    }

    private func convertToM4A(from sourceURL: URL, to destURL: URL, completion: @escaping (Bool) -> Void) {
        Task.detached {
            do {
                let sourceFile = try AVAudioFile(forReading: sourceURL)
                let sourceFormat = sourceFile.processingFormat

                // AVAudioFile with AAC settings accepts PCM buffers via write() — it converts internally
                let outputSettings: [String: Any] = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: sourceFormat.sampleRate,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
                ]

                let destFile = try AVAudioFile(forWriting: destURL, settings: outputSettings)

                let bufferSize: AVAudioFrameCount = 4096
                guard let buffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: bufferSize) else {
                    XLog.error("Failed to create PCM buffer", source: "Audio")
                    completion(false)
                    return
                }

                while sourceFile.framePosition < sourceFile.length {
                    let framesToRead = min(bufferSize, AVAudioFrameCount(sourceFile.length - sourceFile.framePosition))
                    try sourceFile.read(into: buffer, frameCount: framesToRead)
                    try destFile.write(from: buffer)
                }

                XLog.info("✔︎ Converted PCM to M4A: \(destURL.lastPathComponent)", source: "Audio")
                completion(true)
            } catch {
                XLog.error("Audio conversion failed: \(error.localizedDescription)", source: "Audio")
                completion(false)
            }
        }
    }

    private func findTmpFiles(ext: String) -> [URL] {
        let tmpDir = URL(filePath: NSTemporaryDirectory())
        let files = (try? FileManager.default.contentsOfDirectory(at: tmpDir, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        return files.filter { $0.pathExtension == ext }.sorted {
            let d1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let d2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return d1 < d2
        }
    }
    #endif

    private func tmpFileURL(_ name: String? = nil) -> URL {
        let fileName = name ?? UUID().uuidString.lowercased() + ".m4a"
        let tmpDirURL = URL(filePath: NSTemporaryDirectory())
        return tmpDirURL.appendingPathComponent(fileName)
    }

    #if os(iOS)
    private func tmpFileURL(ext: String) -> URL {
        let fileName = UUID().uuidString.lowercased() + "." + ext
        let tmpDirURL = URL(filePath: NSTemporaryDirectory())
        return tmpDirURL.appendingPathComponent(fileName)
    }
    #endif

}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        XLog.info("audio recorder did finish recording with flag \(flag)", source: "Audio")

        if flag && !isTerminating {
            voiceFile = recorder.url
            isCompleted = true
            didCompleteCallback?()
        }

        didFinishCallback?()
        stopMonitoring()
        isRecording = false
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error {
            voiceFile = nil
            XLog.error("audio recorder encode error: \(error.localizedDescription)", source: "Audio")
        }
        stopMonitoring()
        isRecording = false
    }
}
