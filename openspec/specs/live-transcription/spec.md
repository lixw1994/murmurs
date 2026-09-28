## Purpose

Transcribe speech on-device in real time while recording, so the transcript is ready as soon as recording stops.

## Requirements

### Requirement: Live transcription during recording
When the Apple transcription provider is selected and transcription is enabled, the system SHALL perform speech-to-text in real time during audio recording and display progressive results to the user.

#### Scenario: Real-time text display while recording
- **WHEN** user starts recording with Apple provider enabled and transcription enabled
- **THEN** transcribed text SHALL appear progressively on the recording screen as the user speaks

#### Scenario: OpenAI provider selected
- **WHEN** user starts recording with OpenAI provider selected
- **THEN** recording SHALL behave exactly as before (no live transcription, transcription happens after recording stops)

#### Scenario: Transcription disabled
- **WHEN** user starts recording with transcription disabled
- **THEN** recording SHALL behave exactly as before (no live transcription)

### Requirement: Platform-adaptive speech engine
The system SHALL use the best available Apple speech recognition engine based on the iOS version at runtime.

#### Scenario: iOS 26 or later
- **WHEN** the device runs iOS 26+
- **THEN** the system SHALL use `SpeechAnalyzer` for live transcription

#### Scenario: iOS 17 to iOS 25
- **WHEN** the device runs iOS 17 through iOS 25
- **THEN** the system SHALL use `SFSpeechRecognizer` with `SFSpeechAudioBufferRecognitionRequest` for live transcription

### Requirement: Simultaneous recording and transcription
The system SHALL record audio to a file while simultaneously feeding audio buffers to the speech recognizer, so that both a saved audio file and live transcription are produced from a single recording session.

#### Scenario: Audio file is saved after live transcription recording
- **WHEN** user stops a recording that had live transcription active
- **THEN** the system SHALL produce a valid `.m4a` audio file identical in purpose to the current recording output

#### Scenario: Audio buffers fed to recognizer
- **WHEN** recording is in progress with live transcription active
- **THEN** the system SHALL feed audio buffers from `AVAudioEngine` to the active speech recognizer concurrently with writing to the audio file

### Requirement: Pre-populated transcription result
When live transcription was active during recording, the completed recording view SHALL be pre-populated with the transcribed text, skipping the post-recording transcription step.

#### Scenario: Transition from recording to completed view
- **WHEN** user stops recording after live transcription produced text
- **THEN** `RecordingCompletedView` SHALL display the accumulated transcription text immediately without showing a transcription spinner

#### Scenario: Empty live transcription result
- **WHEN** user stops recording but live transcription produced no text (silence or unrecognized speech)
- **THEN** `RecordingCompletedView` SHALL show an empty text editor, same as current behavior when transcription returns empty

### Requirement: AutoSave mode compatibility
The system SHALL support live transcription in autoSave mode by using the accumulated live transcription text as the memo content.

#### Scenario: AutoSave with live transcription
- **WHEN** autoSave is enabled and Apple provider with transcription is active
- **THEN** the memo SHALL be saved automatically with the live-transcribed text as content upon recording stop

### Requirement: Graceful handling of long recordings
The system SHALL handle recordings longer than the SFSpeechRecognizer recognition limit (~1 minute on iOS 17-25) by restarting recognition requests and accumulating partial results.

#### Scenario: Recording exceeds one minute on pre-iOS 26
- **WHEN** user records for more than 1 minute on iOS 17-25 with live transcription
- **THEN** the system SHALL restart the speech recognition request and concatenate results, maintaining continuous transcription display
