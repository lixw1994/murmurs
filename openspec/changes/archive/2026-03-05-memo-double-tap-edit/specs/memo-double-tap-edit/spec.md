## ADDED Requirements

### Requirement: Double-tap to edit memo
The system SHALL open the memo edit sheet when the user double-taps a timeline entry.

#### Scenario: Double-tap on a memo in normal mode
- **WHEN** user double-taps a timeline entry that is not in multi-select mode
- **THEN** the system SHALL present the MemoEditView sheet for that memo

#### Scenario: Double-tap in multi-select mode
- **WHEN** user double-taps a timeline entry while in multi-select mode
- **THEN** the system SHALL NOT open the edit sheet (multi-select behavior takes precedence)

#### Scenario: Double-tap while transcribing or polishing
- **WHEN** user double-taps a memo that is currently being transcribed or polished
- **THEN** the system SHALL still open the edit sheet normally

### Requirement: Auto-focus text editor on edit
The system SHALL automatically focus the text editor and show the keyboard when MemoEditView is presented.

#### Scenario: Edit via double-tap
- **WHEN** MemoEditView is presented after double-tap
- **THEN** the text editor SHALL be focused and the keyboard SHALL appear automatically

#### Scenario: Edit via menu button
- **WHEN** MemoEditView is presented via the edit button in menu or context menu
- **THEN** the text editor SHALL be focused and the keyboard SHALL appear automatically
