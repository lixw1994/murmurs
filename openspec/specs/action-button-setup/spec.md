## Purpose

Make the quick-recording App Shortcut discoverable and usable from Siri, the Shortcuts app, and the Action Button, with setup guidance in Settings.

## Requirements

### Requirement: Intent description metadata
The `StartRecordingIntent` SHALL have a `description` static property providing a human-readable explanation of the intent's purpose for display in Shortcuts app and Action Button configuration.

#### Scenario: Intent displayed in Shortcuts app
- **WHEN** user browses app shortcuts in the Shortcuts app
- **THEN** the Start Recording intent SHALL display a descriptive summary

### Requirement: Siri phrases for voice recording shortcut
The `AppShortcut` for `StartRecordingIntent` SHALL include Siri phrases in both English and Chinese that allow users to trigger recording via Siri or Action Button shortcut selection.

#### Scenario: Siri phrase triggers recording
- **WHEN** user says "Record with Murmurs" to Siri
- **THEN** Murmurs SHALL open and start voice recording

#### Scenario: Chinese Siri phrase triggers recording
- **WHEN** user says "Murmurs开始录音" to Siri
- **THEN** Murmurs SHALL open and start voice recording

### Requirement: Short title for compact display
The `AppShortcut` SHALL include a `shortTitle` for compact display contexts such as Action Button configuration UI.

#### Scenario: Action Button configuration shows shortcut
- **WHEN** user configures Action Button to use a Shortcut in iOS Settings
- **THEN** the Murmurs recording shortcut SHALL appear with a concise title and recognizable icon

### Requirement: Settings guidance for shortcut integration
The Settings screen SHALL include a section that guides users on how to configure Action Button or Siri to start recording.

#### Scenario: User views shortcut setup guidance
- **WHEN** user navigates to Murmurs Settings
- **THEN** a section SHALL display instructions for configuring Action Button or Siri shortcuts

#### Scenario: Guidance links to system settings
- **WHEN** user taps the guidance section
- **THEN** the system SHALL open the relevant iOS Settings page (if available) or display inline instructions
