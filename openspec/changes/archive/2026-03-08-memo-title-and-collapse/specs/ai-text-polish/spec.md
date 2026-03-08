## ADDED Requirements

### Requirement: Auto-generate title after polish
When polish completes successfully, the system SHALL automatically trigger title generation if the AI server is configured, regardless of whether the memo already has a title.

#### Scenario: Polish completes and triggers title update
- **WHEN** polish completes successfully for a memo AND the AI server is configured
- **THEN** the system SHALL automatically generate a new title based on the polished content

#### Scenario: Polish completes without server configured
- **WHEN** polish completes but somehow the AI server is no longer configured
- **THEN** no title generation SHALL be triggered
