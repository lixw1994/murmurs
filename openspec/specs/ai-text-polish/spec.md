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

### Requirement: Dual display of polished and original text
When a memo has polished content, the system SHALL display both the polished and original text, with polished text emphasized and original text de-emphasized.

#### Scenario: Memo with polished content in timeline
- **WHEN** a memo has both `content` and `polishedContent`
- **THEN** the timeline entry SHALL display `polishedContent` as the primary text and `content` as secondary text in a de-emphasized style (smaller font, lighter color)

#### Scenario: Memo without polished content in timeline
- **WHEN** a memo has `content` but no `polishedContent`
- **THEN** the timeline entry SHALL display `content` as the primary text, same as current behavior

#### Scenario: Polished content indicator
- **WHEN** a memo has `polishedContent`
- **THEN** the system SHALL display a visual indicator (sparkle icon) to distinguish AI-polished content from raw transcription

### Requirement: Delete polished content
The system SHALL allow users to delete polished content, reverting the memo display to the original transcription only.

#### Scenario: Delete polish from a polished memo
- **WHEN** user triggers "Delete Polish" on a memo that has `polishedContent`
- **THEN** the system SHALL set `polishedContent` to nil and the memo SHALL display only the original `content`

#### Scenario: Delete polish action availability
- **WHEN** a memo has no `polishedContent`
- **THEN** the "Delete Polish" action SHALL NOT be available

### Requirement: Re-polish content
The system SHALL allow users to re-polish a memo that already has polished content, replacing the previous polish result.

#### Scenario: Re-polish an already polished memo
- **WHEN** user triggers "AI Polish" on a memo that already has `polishedContent`
- **THEN** the system SHALL overwrite the existing `polishedContent` with the new polish result

### Requirement: Streaming polish progress
The system SHALL display real-time streaming feedback while polish is in progress.

#### Scenario: Polish in progress
- **WHEN** a polish operation is streaming
- **THEN** the system SHALL show a loading indicator on the memo being polished

#### Scenario: Polish completes successfully
- **WHEN** the streaming response completes
- **THEN** the system SHALL save the polished text to `polishedContent` and remove the loading indicator

#### Scenario: Polish fails
- **WHEN** the streaming response encounters an error
- **THEN** the system SHALL display an error message and leave the memo unchanged

### Requirement: Polish data persistence
The polished content SHALL be stored as an optional field on the memo entity, persisted via SwiftData.

#### Scenario: Polished content survives app restart
- **WHEN** a memo has been polished and the app is restarted
- **THEN** the `polishedContent` SHALL be restored and displayed as before

#### Scenario: Polished content in export
- **WHEN** a memo with polished content is exported
- **THEN** the export SHALL use `polishedContent` as the primary text (existing export behavior uses `content` — polished content takes precedence when available)
