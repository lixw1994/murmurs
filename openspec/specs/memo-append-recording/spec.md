## ADDED Requirements

### Requirement: Append recording to existing memo
The system SHALL allow users to append a new voice recording to an existing memo, merging the audio and concatenating the transcribed text.

#### Scenario: Append recording entry point
- **WHEN** user opens the context menu on a memo in the timeline
- **THEN** the menu SHALL include a "Continue Recording" option

#### Scenario: Append recording flow
- **WHEN** user selects "Continue Recording" on an existing memo
- **THEN** the system SHALL open the recording interface, and upon completion, merge the new audio with the existing audio file and append the new transcription to the memo's content

#### Scenario: Append to memo without audio
- **WHEN** user selects "Continue Recording" on a memo that has no audio file (text-only memo)
- **THEN** the system SHALL record new audio and set it as the memo's audio file, appending any new transcription to existing content

#### Scenario: Audio merge produces single file
- **WHEN** a recording is appended to a memo with existing audio
- **THEN** the system SHALL merge both audio files into a single `.m4a` file and update the memo's duration to the combined total

### Requirement: Transcription after append
The system SHALL transcribe the appended recording segment and concatenate the result with the existing content.

#### Scenario: Auto-transcribe appended segment
- **WHEN** a recording is appended and auto-transcription is enabled
- **THEN** the system SHALL transcribe only the new audio segment and append the transcribed text to the memo's existing content, separated by a newline

#### Scenario: Append without transcription
- **WHEN** a recording is appended and auto-transcription is disabled
- **THEN** the system SHALL merge the audio files and update duration without modifying the memo's text content

### Requirement: Clear derived content after append
After a recording is appended, the system SHALL clear derived AI content that is no longer consistent with the updated memo.

#### Scenario: Clear polished content after append
- **WHEN** a recording is appended to a memo that has polished content
- **THEN** the system SHALL set `polishedContent` to nil

#### Scenario: Clear title after append
- **WHEN** a recording is appended to a memo that has a title
- **THEN** the system SHALL set `title` to nil

#### Scenario: Auto-regenerate title after transcription
- **WHEN** the appended segment has been transcribed and the AI server is configured
- **THEN** the system SHALL automatically trigger title generation for the updated memo content

### Requirement: Append recording UI feedback
The system SHALL provide feedback during the audio merge process.

#### Scenario: Merge in progress
- **WHEN** the system is merging audio files after append
- **THEN** the system SHALL display a loading indicator

#### Scenario: Merge completes successfully
- **WHEN** the audio merge completes
- **THEN** the system SHALL update the memo and dismiss the recording interface

#### Scenario: Merge fails
- **WHEN** the audio merge encounters an error
- **THEN** the system SHALL display an error message and leave the original memo unchanged
