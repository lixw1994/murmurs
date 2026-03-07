## Why

Currently, transcription only happens after recording completes — the user records audio, stops, then waits for the full file to be transcribed. This creates a disconnected experience. Real-time transcription (text appearing as the user speaks) provides immediate feedback and feels more natural, similar to ChatGPT's voice input experience.

Apple's new SpeechAnalyzer API (iOS 26) offers high-quality on-device streaming transcription, and SFSpeechRecognizer already supports a live audio buffer mode that we're not using. We can support both with a runtime check.

## What Changes

- Add real-time transcription during recording for the **Apple provider**: text appears progressively while the user speaks
- iOS 26+: use `SpeechAnalyzer` for higher accuracy streaming transcription
- iOS 17-25: use `SFSpeechRecognizer` with `SFSpeechAudioBufferRecognitionRequest` + `AVAudioEngine` for live streaming
- Replace `AVAudioRecorder` with `AVAudioEngine` (for Apple provider) to simultaneously record audio and feed audio buffers to the speech recognizer
- The **OpenAI provider** remains unchanged: transcription still happens after recording completes (file upload to Whisper API)
- Update `RecordingView` to display live transcription text during recording
- Update `RecordingCompletedView` to pre-populate with the real-time transcription result

## Capabilities

### New Capabilities
- `live-transcription`: Real-time speech-to-text during recording, with platform-adaptive implementation (SpeechAnalyzer on iOS 26+, SFSpeechRecognizer audio buffer mode on older iOS)

### Modified Capabilities
_(none — no existing specs to modify)_

## Impact

- **Sources/Services/Transcription/**: New `LiveTranscriber` service with platform branching logic
- **Shared/Recorder/AudioRecorder.swift**: Needs to support `AVAudioEngine` path for tapping audio buffers while still recording to file
- **Sources/Modules/Recording/RecordingView.swift**: Display live transcription text overlay during recording
- **Sources/Modules/Recording/RecordingCompletedView(Model).swift**: Accept pre-transcribed text from recording phase
- **Dependencies**: No new SPM dependencies needed — uses Apple frameworks (`Speech`, `AVFoundation`)
- **Deployment target**: Remains iOS 17.0; SpeechAnalyzer features gated behind `#available(iOS 26, *)`
