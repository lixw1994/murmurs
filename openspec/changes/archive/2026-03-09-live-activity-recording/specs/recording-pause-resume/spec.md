## MODIFIED Requirements

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
