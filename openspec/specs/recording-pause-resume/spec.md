## Purpose

Allow users to pause and resume an in-progress recording without ending the session.

## Requirements

### Requirement: Pause and resume during recording
The system SHALL allow users to pause an active recording and resume it, producing a single continuous audio file. State changes SHALL be propagated to any active Live Activity.

#### Scenario: Pause an active recording
- **WHEN** user taps the pause button during an active recording
- **THEN** the recording SHALL pause, the timer SHALL stop, the UI SHALL indicate paused state, and the Live Activity SHALL update to show paused state

#### Scenario: Resume a paused recording
- **WHEN** user taps the resume button while recording is paused
- **THEN** the recording SHALL resume from where it left off, the timer SHALL continue, and the Live Activity SHALL update to show active recording state

#### Scenario: Stop a paused recording
- **WHEN** user taps the stop button while recording is paused
- **THEN** the recording SHALL finalize and produce the audio file containing all recorded segments

#### Scenario: Multiple pause-resume cycles
- **WHEN** user pauses and resumes multiple times during a single recording session
- **THEN** the final audio file SHALL contain all recorded segments as a continuous file

### Requirement: Pause button availability
The pause button SHALL only be available when the recording mode supports it.

#### Scenario: Pause available in standard recording mode
- **WHEN** recording is using AVAudioRecorder (standard mode, no live transcription)
- **THEN** the pause button SHALL be displayed and functional

#### Scenario: Pause unavailable in live transcription mode
- **WHEN** recording is using AVAudioEngine (live transcription enabled with Apple Speech)
- **THEN** the pause button SHALL NOT be displayed

### Requirement: Paused recording visual feedback
The system SHALL provide clear visual feedback when recording is in paused state.

#### Scenario: Paused state indicator
- **WHEN** recording is paused
- **THEN** the UI SHALL show a paused indicator (e.g., pause icon changes to resume icon) and the waveform SHALL stop updating

#### Scenario: Timer behavior during pause
- **WHEN** recording is paused
- **THEN** the recording timer SHALL stop incrementing and SHALL resume from the paused time when recording resumes
