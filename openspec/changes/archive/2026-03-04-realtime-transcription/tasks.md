## 1. LiveTranscriber Service

- [x] 1.1 Create `LiveTranscriberProtocol` with `start(lang:) -> AsyncStream<String>`, `append(buffer:)`, `stop() async -> String`
- [x] 1.2 Implement `SFSpeechLiveTranscriber` (iOS 17-25) using `SFSpeechRecognizer` + `SFSpeechAudioBufferRecognitionRequest`, including auto-restart for recordings > 1 minute
- [x] 1.3 Implement `SpeechAnalyzerLiveTranscriber` (iOS 26+) using `SpeechAnalyzer` + transcriber module
- [x] 1.4 Create `LiveTranscriberFactory` that returns the appropriate implementation based on `#available(iOS 26, *)`

## 2. AudioRecorder AVAudioEngine Mode

- [x] 2.1 Add `AVAudioEngine`-based recording mode to `AudioRecorder` with an `onBufferCaptured: ((AVAudioPCMBuffer) -> Void)?` callback
- [x] 2.2 Implement writing PCM buffers to a temporary audio file via `AVAudioFile` during engine-mode recording
- [x] 2.3 Implement PCM → M4A (AAC) conversion on recording stop, producing the same `.m4a` output format as the current `AVAudioRecorder` path
- [x] 2.4 Preserve existing `AVAudioRecorder` path when live transcription is not active (OpenAI provider or transcription disabled)
- [x] 2.5 Ensure waveform samples (`samples: [Float]`) continue to work in engine mode by reading audio levels from the tap buffer

## 3. Recording UI Integration

- [x] 3.1 Create `RecordingViewModel` to orchestrate `AudioRecorder` (engine mode) + `LiveTranscriber`, deciding which mode to use based on `config.transEnabled` and `config.transProvider`
- [x] 3.2 Update `RecordingView` to display live transcription text below the waveform during recording (scrollable, auto-scrolling to latest text)
- [x] 3.3 Pass accumulated transcription text from `RecordingView` to `RecordingCompletedView` when recording stops
- [x] 3.4 Update `RecordingCompletedViewModel` to accept optional pre-transcribed text and skip the post-recording transcription call when provided

## 4. AutoSave Path

- [x] 4.1 Update `RecordingView`'s autoSave flow to use the live-transcribed text as memo content when live transcription was active

## 5. Testing

- [x] 5.1 Add MockLiveTranscriber for testing (SFSpeechRecognizer cannot be mocked without device)
- [x] 5.2 Add unit tests for `RecordingViewModel` covering: Apple provider → engine mode, OpenAI provider → recorder mode, transcription disabled → recorder mode
- [x] 5.3 Add unit test for `RecordingCompletedViewModel` pre-populated text path (skip transcription when text already provided)
