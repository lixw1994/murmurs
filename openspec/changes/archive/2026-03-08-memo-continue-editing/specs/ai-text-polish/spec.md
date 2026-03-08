## MODIFIED Requirements

### Requirement: AI polish for transcribed text
The system SHALL allow users to polish memo transcription text using an OpenAI-compatible chat API, producing a cleaner version while preserving the original.

#### Scenario: Polish a memo with transcribed content
- **WHEN** user triggers "AI Polish" on a memo that has transcribed content
- **THEN** the system SHALL send the content to the configured chat API with a polish prompt and stream the polished result back into `polishedContent`

#### Scenario: Polish a memo without content
- **WHEN** user views a memo that has no transcribed content (empty or nil)
- **THEN** the "AI Polish" action SHALL NOT be available

#### Scenario: Server not configured
- **WHEN** user triggers "AI Polish" but no OpenAI-compatible server is configured
- **THEN** the system SHALL display an error indicating the server must be configured in Settings

#### Scenario: Content edited after polish invalidates polish
- **WHEN** user appends a recording or edits the memo content after polishing
- **THEN** the system SHALL clear `polishedContent` to nil, as the polish no longer reflects the current content
