## Purpose

Display an active recording session in the Dynamic Island via Live Activities, providing real-time status and interactive controls.

## Requirements

### Requirement: Live Activity starts when recording begins
The system SHALL start a Live Activity when audio recording begins, displaying the recording in the Dynamic Island.

#### Scenario: Recording starts normally
- **WHEN** user starts a new recording
- **THEN** a Live Activity SHALL appear in the Dynamic Island showing elapsed time "00:00" and a recording indicator

#### Scenario: Recording starts in live transcription mode
- **WHEN** user starts a recording with live transcription enabled (AVAudioEngine mode)
- **THEN** a Live Activity SHALL appear in the Dynamic Island showing elapsed time and a recording indicator

#### Scenario: ActivityKit not available
- **WHEN** the device does not support Live Activities (e.g., older hardware)
- **THEN** the recording SHALL proceed normally without a Live Activity and no error SHALL be shown

### Requirement: Live Activity displays recording duration
The system SHALL update the Live Activity to show the current recording duration in real-time.

#### Scenario: Duration updates during recording
- **WHEN** recording is active and not paused
- **THEN** the Dynamic Island SHALL display the elapsed recording time, updated every second, in MM:SS format

#### Scenario: Duration freezes when paused
- **WHEN** recording is paused
- **THEN** the displayed duration SHALL stop updating and remain at the time when pause occurred

#### Scenario: Duration resumes after unpause
- **WHEN** recording resumes from a paused state
- **THEN** the displayed duration SHALL resume updating from where it stopped

### Requirement: Live Activity shows recording state
The system SHALL visually distinguish between active recording and paused states in the Dynamic Island.

#### Scenario: Active recording state
- **WHEN** recording is active and not paused
- **THEN** the Dynamic Island SHALL display a recording indicator (e.g., red dot or pulsing animation)

#### Scenario: Paused recording state
- **WHEN** recording is paused
- **THEN** the Dynamic Island SHALL display a paused indicator (e.g., pause icon) instead of the recording indicator

### Requirement: Dynamic Island compact and minimal presentations
The system SHALL render appropriate content for both compact and minimal Dynamic Island presentations.

#### Scenario: Compact leading presentation
- **WHEN** the Dynamic Island shows the compact leading view
- **THEN** it SHALL display the app icon or a microphone icon

#### Scenario: Compact trailing presentation
- **WHEN** the Dynamic Island shows the compact trailing view
- **THEN** it SHALL display the current elapsed time in MM:SS format

#### Scenario: Minimal presentation
- **WHEN** another Live Activity takes the primary Dynamic Island slot
- **THEN** the recording activity SHALL display a minimal circular view with a recording indicator

### Requirement: Dynamic Island expanded view with controls
The system SHALL provide interactive controls in the expanded Dynamic Island view.

#### Scenario: Expanded view layout
- **WHEN** user long-presses the Dynamic Island to expand it
- **THEN** the expanded view SHALL display: recording duration, recording state indicator, pause/resume button (when available), and stop button

#### Scenario: Pause button in expanded view (standard mode)
- **WHEN** recording is in standard mode (AVAudioRecorder) and the expanded view is shown
- **THEN** a pause/resume toggle button SHALL be displayed and functional

#### Scenario: No pause button in engine mode
- **WHEN** recording is in AVAudioEngine mode (live transcription) and the expanded view is shown
- **THEN** the pause button SHALL NOT be displayed; only the stop button SHALL be shown

#### Scenario: Stop recording from expanded view
- **WHEN** user taps the stop button in the expanded Dynamic Island view
- **THEN** the recording SHALL stop and the Live Activity SHALL begin its dismissal

### Requirement: Live Activity ends when recording stops
The system SHALL dismiss the Live Activity when recording ends.

#### Scenario: Recording stopped by user
- **WHEN** user stops the recording (from the app or Dynamic Island)
- **THEN** the Live Activity SHALL be dismissed after a brief final state showing "Recording saved"

#### Scenario: Recording terminated (cancelled)
- **WHEN** user terminates/cancels the recording
- **THEN** the Live Activity SHALL be dismissed immediately

#### Scenario: App crash or unexpected termination
- **WHEN** the app terminates unexpectedly during recording
- **THEN** the Live Activity SHALL be automatically dismissed by the system (stale activity policy)

### Requirement: Tapping Live Activity opens recording view
The system SHALL navigate to the active recording view when the user taps the Dynamic Island.

#### Scenario: Tap compact or minimal Dynamic Island
- **WHEN** user taps the compact or minimal Dynamic Island presentation
- **THEN** Murmurs SHALL open and display the active recording view

#### Scenario: App already in foreground
- **WHEN** user taps the Dynamic Island while Murmurs is already in the foreground
- **THEN** the recording view SHALL be presented if not already visible
