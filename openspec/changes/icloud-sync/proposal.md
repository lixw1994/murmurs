## Why

Users record memos on iPhone, Apple Watch, or iPad but data stays local to each device. The #1 user request (issue #32) is cross-device access — "record on watch/phone, review on iPad." Currently the only sync is unidirectional Watch → iPhone via WatchConnectivity. There is no way to view memos or summaries across iPhone and iPad. Export (CSV/Markdown/PDF) is a poor workaround.

## What Changes

- Enable CloudKit-backed SwiftData sync for MemoEntity and SummaryEntity across all devices signed into the same iCloud account
- Text content (transcriptions, titles, metadata, summaries) always syncs when iCloud is enabled
- Optional audio sync toggle — users can choose whether to also sync audio files via CKAsset (off by default to save iCloud storage)
- Add iCloud sync toggle in Settings so users can opt in/out
- Add sync status indicators in the UI (last synced time, sync-in-progress)
- Add PromptEntity sync so custom prompts are shared across devices
- Handle conflict resolution with a "last-writer-wins" strategy based on `updatedAt`

## Non-goals

- Real-time collaborative editing (single user, multiple devices)
- WebDAV or third-party sync (requested by one user in #32, but iCloud covers the primary use case)
- watchOS iCloud sync (watchOS will continue using WatchConnectivity → iPhone as the relay; iCloud sync is iPhone/iPad only)
- Migrating existing Readwise sync — it remains independent
- End-to-end encryption beyond what iCloud provides natively

## Capabilities

### New Capabilities
- `icloud-sync`: CloudKit-backed SwiftData sync for memos, summaries, and prompts across iPhone and iPad. Text always syncs; audio sync is optional (off by default). Includes conflict resolution, sync settings UI, and status indicators.

### Modified Capabilities
_(none — existing specs are implementation-level and not affected at the requirements level)_

## Impact

- **Persistence layer**: `DataContainer` must switch from local-only `ModelConfiguration` to CloudKit-enabled configuration
- **Data models**: PromptEntity needs a stable UUID primary key. UsageEntity remains local-only and must be excluded from sync.
- **project.yml**: Add CloudKit entitlement and iCloud container identifier (`iCloud.com.tangyue.murmurs`)
- **Audio files**: Optional sync via `@Attribute(.externalStorage)` → CKAsset. When audio sync is off, `file` field syncs as filename string only; synced devices show text without playback. When on, audio data is included and playable on all devices.
- **Settings UI**: New sync toggle and status display
- **Dependencies**: No new SPM dependencies expected — CloudKit and SwiftData CloudKit support are first-party frameworks
- **App size / performance**: Initial sync of existing data may take time; need progress indication and background sync support
