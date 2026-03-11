## ADDED Requirements

### Requirement: CloudKit-backed data sync
The system SHALL sync MemoEntity, SummaryEntity, and PromptEntity records across all devices signed into the same iCloud account when iCloud sync is enabled. UsageEntity MUST remain local-only and SHALL NOT be synced.

#### Scenario: Memo created on iPhone appears on iPad
- **WHEN** user creates a memo on iPhone with iCloud sync enabled
- **THEN** the memo (including transcribed text, title, metadata) SHALL appear on iPad within the next CloudKit sync cycle

#### Scenario: Summary created on iPad appears on iPhone
- **WHEN** user generates a summary on iPad with iCloud sync enabled
- **THEN** the summary SHALL appear on iPhone after sync

#### Scenario: Custom prompt syncs across devices
- **WHEN** user creates or edits a custom prompt on one device
- **THEN** the prompt SHALL be available on all other synced devices

#### Scenario: Usage data stays local
- **WHEN** user has iCloud sync enabled and uses AI features
- **THEN** UsageEntity records SHALL only exist on the device where the usage occurred

### Requirement: Optional audio file sync
The system SHALL provide a sub-toggle `icloud_sync_audio` (default off) under the iCloud sync master toggle. When off, only text/metadata syncs and audio files remain local. When on, audio files SHALL be synced via `@Attribute(.externalStorage)` (CKAsset).

#### Scenario: Audio sync off — text syncs, audio stays local
- **WHEN** user has iCloud sync enabled but audio sync disabled, and records a memo on iPhone
- **THEN** the memo text, title, and metadata SHALL appear on iPad after sync, but audio playback SHALL NOT be available on iPad

#### Scenario: Audio sync on — audio available on all devices
- **WHEN** user has both iCloud sync and audio sync enabled, and records a memo on iPhone
- **THEN** the memo text and audio file SHALL both sync to iPad, and audio playback SHALL be available on iPad

#### Scenario: Audio player hidden for remote memos without audio
- **WHEN** a synced memo has no local audio file and no synced audioData on the current device
- **THEN** the system SHALL hide the audio player/waveform and display a note indicating audio is on the recording device

#### Scenario: Audio sync toggle shows storage warning
- **WHEN** user enables the audio sync toggle
- **THEN** the system SHALL display a warning that audio sync may use significant iCloud storage

#### Scenario: Watch recording with audio sync on
- **WHEN** user records on Apple Watch, recording transfers to iPhone, and audio sync is enabled
- **THEN** the memo text and audio SHALL sync from iPhone to iPad via iCloud

### Requirement: iCloud sync toggle
The system SHALL provide a toggle in Settings for the user to enable or disable iCloud sync. The toggle MUST default to off.

#### Scenario: User enables iCloud sync
- **WHEN** user toggles iCloud sync on in Settings
- **THEN** the system SHALL configure CloudKit-backed persistence and begin syncing existing local data to iCloud

#### Scenario: User disables iCloud sync
- **WHEN** user toggles iCloud sync off in Settings
- **THEN** the system SHALL stop syncing new changes, local data SHALL be preserved, and data already in iCloud SHALL remain until manually deleted

#### Scenario: iCloud account not available
- **WHEN** user attempts to enable iCloud sync but is not signed into iCloud on the device
- **THEN** the system SHALL display an informative message and the toggle SHALL remain off

### Requirement: Sync status display
The system SHALL display sync status information in Settings, including sync state and last successful sync time.

#### Scenario: Sync in progress
- **WHEN** CloudKit is actively importing or exporting data
- **THEN** the system SHALL display a sync-in-progress indicator in Settings

#### Scenario: Sync completed
- **WHEN** the last sync operation completed successfully
- **THEN** the system SHALL display the timestamp of the last successful sync

#### Scenario: Sync error
- **WHEN** a sync operation fails (network error, storage quota, etc.)
- **THEN** the system SHALL display an error description to the user

### Requirement: Conflict resolution
The system SHALL use a last-writer-wins strategy based on `updatedAt` timestamp for resolving conflicts when the same record is modified on multiple devices.

#### Scenario: Same memo edited on two devices
- **WHEN** a memo is edited on both iPhone and iPad before sync occurs
- **THEN** the version with the later `updatedAt` timestamp SHALL be preserved

#### Scenario: Memo deleted on one device
- **WHEN** a memo is deleted on iPhone while still present on iPad
- **THEN** the deletion SHALL propagate to iPad after sync, removing the memo

### Requirement: Data model compatibility
PromptEntity SHALL have a stable UUID primary key to support CloudKit sync. All synced entity properties MUST be optional or have default values to satisfy CloudKit requirements.

#### Scenario: Existing prompts get UUIDs on migration
- **WHEN** the app updates and PromptEntity gains a UUID field
- **THEN** all existing prompts SHALL receive auto-generated UUIDs without data loss

#### Scenario: New properties have defaults
- **WHEN** a synced record arrives from another device with newer schema fields
- **THEN** missing fields SHALL use their defined default values without crashing
