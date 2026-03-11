## Context

Murmurs stores all data locally per device using SwiftData with a plain SQLite store (`DataModel.sqlite`). Four entities exist: MemoEntity, SummaryEntity, PromptEntity, UsageEntity. Audio files are stored separately in `Documents/audio/`. The only cross-device data flow is Watch → iPhone via WatchConnectivity file transfer.

MemoEntity and SummaryEntity already have `syncedAt` fields and `needsSync` computed properties (used for Readwise sync), indicating the codebase was designed with sync awareness. PromptEntity lacks a UUID primary key. UsageEntity is device-specific analytics.

## Goals / Non-Goals

**Goals:**
- Enable CloudKit-backed SwiftData sync for MemoEntity, SummaryEntity, and PromptEntity across iPhone and iPad
- Text content always syncs; audio file sync is optional (user-controlled toggle, off by default)
- Provide user-facing sync toggle and status in Settings
- Handle first-time migration of existing local data to CloudKit
- Maintain backward compatibility — users who don't enable iCloud should see zero behavior change

**Non-Goals:**
- watchOS CloudKit sync (continues using WatchConnectivity relay)
- Custom conflict resolution UI (rely on last-writer-wins via `updatedAt`)
- Syncing UsageEntity (device-local analytics)
- Real-time push notifications of sync changes

## Decisions

### Decision 1: Use SwiftData + CloudKit (NSPersistentCloudKitContainer) over manual CloudKit API

**Choice**: SwiftData's built-in CloudKit integration via `ModelConfiguration(cloudKitDatabase:)`

**Rationale**: SwiftData on iOS 17+ natively supports CloudKit sync with minimal configuration. It handles schema migration, change tracking, and conflict resolution automatically. Manual CKRecord management would require significantly more code and maintenance for the same result.

**Alternatives considered**:
- Manual CloudKit API (CKRecord/CKDatabase) — full control but enormous implementation effort
- Third-party sync (e.g., Realm Sync) — adds dependency, migration cost

### Decision 2: Optional audio sync via separate toggle

**Choice**: Text/metadata always syncs when iCloud is enabled. A second toggle `icloud_sync_audio` (default off) controls whether audio files are also synced via `@Attribute(.externalStorage)` → CKAsset.

**Rationale**: Text is tiny (~few KB per memo), audio is large (~500KB per minute). By defaulting audio sync off, users get instant cross-device text access without hitting CloudKit's 1GB free tier limit. Power users who want full audio playback on all devices can opt in, understanding the storage trade-off.

**Implementation**:
- Add `audioData: Data?` with `@Attribute(.externalStorage)` to MemoEntity
- When `icloud_sync_audio` is on: populate `audioData` from filesystem on save; on sync receive, write `audioData` back to local filesystem
- When `icloud_sync_audio` is off: `audioData` stays nil, audio files remain local only
- UI: synced memos without local audio hide the player and show "录音仅在录制设备上可用"

**Affected files**:
- `Sources/Persistence/MemoEntity.swift` — add `audioData` property
- `Sources/App/Config.swift` — add `icloud_sync_audio` setting
- `Sources/Persistence/DataContainer.swift` — audio data coordination logic
- Timeline views — handle missing local audio gracefully

**Alternatives considered**:
- Always sync audio — risks hitting storage limits for all users
- Never sync audio — limits the feature for users who want full cross-device experience
- iCloud Documents container for audio — complex file coordination, harder to keep in sync with DB records

### Decision 3: Dual-store approach — CloudKit store + local-only store

**Choice**: Use two `ModelConfiguration` instances in the same `ModelContainer`:
1. **CloudKit store**: MemoEntity, SummaryEntity, PromptEntity (synced)
2. **Local store**: UsageEntity (not synced)

**Rationale**: UsageEntity tracks per-device API usage and MUST NOT sync across devices. SwiftData supports multiple configurations in one container, each covering different entity types.

**Affected files**:
- `Sources/Persistence/DataContainer.swift` — configure dual stores
- `project.yml` — add CloudKit entitlement and iCloud container

### Decision 4: PromptEntity needs a UUID primary key (renumbered from original)

**Choice**: Add `entityId: String` as `@Attribute(.unique)` primary key to PromptEntity, defaulting to `UUID().uuidString`.

**Rationale**: CloudKit requires every synced record to have a unique identifier. PromptEntity currently lacks one. Migration adds the field with a default value for existing records.

**Affected file**: `Sources/Persistence/PromptEntity.swift`

### Decision 5: Two-level sync toggles via existing Config (AppStorage) pattern

**Choice**: Add two settings to `Config.swift`:
1. `icloud_sync_enabled` (default `false`) — master switch for iCloud sync
2. `icloud_sync_audio` (default `false`) — sub-toggle for audio file sync, only visible when master is on

**Rationale**: Follows the existing pattern used by `readwise_sync_enabled`. Two-level design gives users control over storage usage. Audio sync toggle is nested under the master toggle to avoid confusion.

**Affected files**:
- `Sources/App/Config.swift` — two new settings
- `Sources/Modules/Settings/` — UI toggles (audio toggle disabled/hidden when master is off)
- `Sources/Persistence/DataContainer.swift` — conditional CloudKit setup + audio data coordination

### Decision 6: Sync status via NotificationCenter + observable state

**Choice**: Expose sync status (idle, syncing, error, last-synced-time) through an `@Observable` property on DataContainer or a dedicated SyncManager, driven by `NSPersistentCloudKitContainer.eventChangedNotification`.

**Rationale**: CloudKit posts notifications for import/export events. We observe these and surface status in Settings. Follows the existing NotificationCenter pattern used throughout the app.

**Affected files**:
- `Sources/Persistence/DataContainer.swift` or new `Sources/Services/SyncManager.swift`
- `Sources/Modules/Settings/` — status display

## Risks / Trade-offs

**[Risk] CloudKit storage limits (free tier: 1GB) when audio sync is enabled**
→ Mitigation: Audio sync is off by default. When user enables it, show a warning about iCloud storage usage. Text-only sync uses negligible storage (~few KB per memo). Consider displaying estimated iCloud usage in Settings.

**[Risk] SwiftData + CloudKit requires all synced properties to be optional**
→ Mitigation: Audit MemoEntity/SummaryEntity/PromptEntity — most properties are already optional or have defaults. Non-optional properties need default values in the model definition.

**[Risk] Toggling sync off after data has been synced**
→ Mitigation: Disabling sync stops future syncing but keeps local data intact. CloudKit data remains in iCloud until manually deleted. Document this behavior clearly.

**[Risk] Watch recordings arriving via WatchConnectivity during active CloudKit sync**
→ Mitigation: No conflict — WatchConnectivity inserts into the local/CloudKit store on iPhone, which then syncs to other devices normally.

## Migration Plan

1. **Schema migration**: SwiftData handles lightweight migration automatically. Adding `entityId` to PromptEntity and `audioData` to MemoEntity are additive changes.
2. **First-time sync**: When user enables iCloud sync, existing local data is automatically pushed to CloudKit by `NSPersistentCloudKitContainer`.
3. **Rollback**: User can disable sync in Settings. Local data is preserved. No destructive migration needed.

## Open Questions

1. Do we need a premium gate for iCloud sync, or should it be available to all users?
2. When user turns audio sync on with existing memos, should we backfill `audioData` eagerly or lazily?
