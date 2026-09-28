## Purpose

Generate concise AI titles for memos, automatically after transcription or on demand.

## Requirements

### Requirement: AI title generation for memos
The system SHALL allow generating a short title (≤15 characters) for a memo using an OpenAI-compatible chat API. The title SHALL be stored in the `title` field of MemoEntity.

#### Scenario: Generate title for a memo with content
- **WHEN** title generation is triggered for a memo that has text content
- **THEN** the system SHALL send the content to the configured chat API with a title-generation prompt and store the returned title in `memo.title`

#### Scenario: Generate title for a memo without content
- **WHEN** a memo has no text content (empty or nil)
- **THEN** title generation SHALL NOT be triggered

#### Scenario: Server not configured
- **WHEN** title generation is triggered but no AI server is configured
- **THEN** the system SHALL silently skip title generation (no error shown for automatic triggers)

### Requirement: Automatic title generation after transcription
The system SHALL automatically trigger title generation when transcription completes successfully, if the AI server is configured and the memo has no title.

#### Scenario: Transcription completes with server configured
- **WHEN** transcription completes successfully AND the AI server is configured AND the memo has no title
- **THEN** the system SHALL automatically generate a title for the memo

#### Scenario: Transcription completes without server configured
- **WHEN** transcription completes successfully AND the AI server is NOT configured
- **THEN** no title generation SHALL be triggered

#### Scenario: Transcription completes but memo already has title
- **WHEN** transcription completes successfully AND the memo already has a title
- **THEN** no automatic title generation SHALL be triggered

### Requirement: Manual title generation via menu
The system SHALL provide menu actions for users to manually generate, re-generate, or delete titles.

#### Scenario: Generate title action available
- **WHEN** a memo has text content AND the AI server is configured AND the memo has no title
- **THEN** a "Generate Title" action SHALL be available in the memo's menu

#### Scenario: Re-generate title action available
- **WHEN** a memo has text content AND the AI server is configured AND the memo already has a title
- **THEN** a "Re-generate Title" action SHALL be available in the memo's menu

#### Scenario: Delete title action available
- **WHEN** a memo has a title
- **THEN** a "Delete Title" action SHALL be available in the memo's menu

#### Scenario: Delete title
- **WHEN** user triggers "Delete Title"
- **THEN** the system SHALL set `memo.title` to nil

### Requirement: Title generation progress indication
The system SHALL display a progress indicator while title generation is in progress.

#### Scenario: Title generation in progress
- **WHEN** title generation is running for a memo
- **THEN** a subtle loading indicator SHALL be shown on that memo entry

#### Scenario: Title generation fails
- **WHEN** title generation encounters an error from a manual trigger
- **THEN** the system SHALL display an error message on the memo entry

#### Scenario: Title generation fails from automatic trigger
- **WHEN** title generation encounters an error from an automatic trigger (post-transcription)
- **THEN** the system SHALL log the error but NOT display it to the user

### Requirement: Title data persistence
The title SHALL be stored as an optional String field on MemoEntity, persisted via SwiftData.

#### Scenario: Title survives app restart
- **WHEN** a memo has a generated title and the app is restarted
- **THEN** the title SHALL be restored and displayed as before

### Requirement: Title display in timeline
When a memo has a title, the timeline entry SHALL display the title prominently above the content text.

#### Scenario: Memo with title in timeline
- **WHEN** a memo has a `title`
- **THEN** the timeline entry SHALL display the title in a bold, prominent style above the content text

#### Scenario: Memo without title in timeline
- **WHEN** a memo has no `title`
- **THEN** the timeline entry SHALL display as before (content only)
