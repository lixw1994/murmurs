## Context

The app currently uses `AVAudioRecorder` to record audio to a file, then transcribes the complete file using either `SFSpeechURLRecognitionRequest` (Apple) or OpenAI Whisper API. Transcription is a separate post-recording step — the user sees a spinner and waits.

The goal is to show transcription text progressively during recording when the Apple provider is selected. This requires switching from file-based recording to an `AVAudioEngine`-based approach that can simultaneously write audio to disk and feed audio buffers to a speech recognizer.

Key constraint: the OpenAI provider does not support streaming transcription (Whisper API requires a complete file upload), so the existing post-recording flow must be preserved for that path.

## Goals / Non-Goals

**Goals:**
- Show real-time transcription text during recording when Apple transcription provider is selected
- Use `SpeechAnalyzer` on iOS 26+ for better accuracy; fall back to `SFSpeechAudioBufferRecognitionRequest` on iOS 17-25
- Continue writing audio to a file during recording (needed for playback and potential OpenAI re-transcription)
- Pass the live transcription result to `RecordingCompletedView` so the user doesn't wait again

**Non-Goals:**
- Real-time transcription for the OpenAI provider (would require Realtime API / WebSocket — separate effort)
- Changing the Watch app recording flow
- Supporting real-time transcription in background/queue transcription

## Decisions

### 1. AVAudioEngine for dual-purpose audio pipeline

**Decision:** When the Apple provider is active and transcription is enabled, use `AVAudioEngine` instead of `AVAudioRecorder` to capture audio. Install a tap on the input node to:
1. Write audio buffers to a file via `AVAudioFile`
2. Feed the same buffers to the speech recognizer

**Rationale:** `AVAudioRecorder` doesn't expose raw audio buffers. `AVAudioEngine` gives us access to PCM buffers which both `SFSpeechAudioBufferRecognitionRequest` and `SpeechAnalyzer` require. When OpenAI provider is selected (or transcription is disabled), we continue using `AVAudioRecorder` as-is — no change to that path.

**Alternative considered:** Running `AVAudioRecorder` alongside a separate `AVAudioEngine` tap. Rejected because dual audio sessions are fragile and iOS may not allow two simultaneous captures.

### 2. Platform-adaptive LiveTranscriber

**Decision:** Create a `LiveTranscriber` class with a unified async interface that internally branches:

```
protocol LiveTranscriberProtocol {
    func start(lang: TranscriptionLang) -> AsyncStream<String>
    func append(buffer: AVAudioPCMBuffer)
    func stop() async -> String
}
```

- iOS 26+: implementation uses `SpeechAnalyzer` + `SpeechTranscriber` module
- iOS 17-25: implementation uses `SFSpeechRecognizer` + `SFSpeechAudioBufferRecognitionRequest`

**Rationale:** Encapsulates platform differences behind a single protocol. The recording layer doesn't need to know which speech engine is in use.

### 3. Integration point: RecordingView, not AudioRecorder

**Decision:** The live transcription orchestration lives in `RecordingView` / a new `RecordingViewModel`, not inside `AudioRecorder`. `AudioRecorder` gains an optional `AVAudioEngine` mode and exposes audio buffers via a callback, but doesn't know about transcription.

**Rationale:** `AudioRecorder` is in `Shared/` (used by watchOS too). Transcription is iOS-only. Keeping them decoupled avoids pulling Speech framework into the Watch target.

### 4. Audio format handling

**Decision:** `AVAudioEngine` input tap provides PCM buffers (typically 16kHz or device-native sample rate). We write these to a temporary `.caf` file via `AVAudioFile`, then convert to `.m4a` (AAC) on stop — or write directly to AAC using `AVAudioConverter`.

**Rationale:** Speech recognizers need PCM input. The app stores `.m4a` files. We need a conversion step. Writing PCM first then converting is simpler and more reliable than real-time AAC encoding.

### 5. Conditional activation

**Decision:** Live transcription activates only when ALL conditions are met:
- `config.transEnabled == true`
- `config.transProvider == .apple`
- Not in `autoSave` mode (user needs to see the text)

When conditions aren't met, recording uses the existing `AVAudioRecorder` path — zero behavior change.

**Rationale:** Minimizes blast radius. OpenAI users, autoSave users, and transcription-disabled users see no change at all.

## Risks / Trade-offs

- **[Risk] SFSpeechRecognizer has a ~1 minute limit per recognition request** → Mitigation: For recordings > 1 minute, restart the recognition request periodically. Accumulate partial results. Accept that very long recordings may have brief gaps.

- **[Risk] AVAudioEngine recording quality may differ from AVAudioRecorder** → Mitigation: Match sample rate (24kHz) and ensure AAC conversion produces equivalent quality. Test with playback comparison.

- **[Risk] SpeechAnalyzer is iOS 26 only, not yet widely available** → Mitigation: It's behind `#available` check. The SFSpeechRecognizer fallback covers iOS 17-25. Feature degrades gracefully.

- **[Trade-off] Increased complexity in AudioRecorder** → Accepted: The class now has two recording modes (AVAudioRecorder vs AVAudioEngine). This is contained and the mode is chosen once at recording start.

- **[Trade-off] PCM → M4A conversion adds a brief delay on stop** → Accepted: Conversion of a few minutes of audio is fast (<1 second). User won't notice since RecordingCompletedView already has a loading moment.
