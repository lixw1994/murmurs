## 1. Project Configuration

- [x] 1.1 Add CloudKit entitlement and iCloud container identifier (`iCloud.com.tangyue.murmurs`) to `project.yml` for the Murmurs iOS target. Run `xcodegen` and verify build succeeds.

## 2. Data Model Updates

- [x] 2.1 Add `entityId: String` primary key with `@Attribute(.unique)` to `PromptEntity`, defaulting to `UUID().uuidString`. Verify build.
- [x] 2.2 Add `audioData: Data?` property with `@Attribute(.externalStorage)` to `MemoEntity` for optional audio sync via CKAsset. Verify build.
- [x] 2.3 Audit all synced entity properties (MemoEntity, SummaryEntity, PromptEntity) — ensure all are optional or have default values for CloudKit compatibility. Fix any non-optional properties. Verify build.

## 3. Config & Dual-Store DataContainer

- [x] 3.1 Add two settings to `Config.swift` using `@AppStorage`: `icloud_sync_enabled` (default `false`) and `icloud_sync_audio` (default `false`). Verify build.
- [x] 3.2 Refactor `DataContainer.swift` to support dual `ModelConfiguration`: a CloudKit-enabled store for MemoEntity/SummaryEntity/PromptEntity and a local-only store for UsageEntity. When `icloud_sync_enabled` is false, both stores are local-only. Verify build.
- [x] 3.3 Add logic to re-initialize `ModelContainer` when the iCloud sync toggle changes. Verify build.

## 4. Audio Data Coordination

- [x] 4.1 When `icloud_sync_audio` is on: populate `MemoEntity.audioData` from the filesystem audio file when saving a new memo. Verify build.
- [x] 4.2 When a synced memo arrives from CloudKit with `audioData` but no local audio file: write `audioData` back to `Documents/audio/` so local playback works. Verify build.
- [x] 4.3 When `icloud_sync_audio` is off: ensure `audioData` stays nil — audio files remain local only. Verify build.

## 5. Audio Player Handling for Remote Memos

- [x] 5.1 Update Timeline memo views to detect when a synced memo has no local audio file and no `audioData`. Hide audio player/waveform and show a text hint ("录音仅在录制设备上可用"). Verify build.

## 6. Sync Status Observation

- [x] 6.1 Create a `SyncStatus` observable (enum: idle, syncing, error, lastSynced) and observe `NSPersistentCloudKitContainer.eventChangedNotification` in DataContainer to update it. Verify build.
- [x] 6.2 Expose sync status through DataContainer or a dedicated `SyncManager` so ViewModels can read it. Verify build.

## 7. Settings UI

- [x] 7.1 Add iCloud sync master toggle row to Settings view, bound to `Config.icloud_sync_enabled`. Include check for iCloud account availability — show alert if not signed in. Verify build.
- [x] 7.2 Add audio sync sub-toggle below master toggle, bound to `Config.icloud_sync_audio`. Only visible/enabled when master toggle is on. Show storage warning when user enables it. Verify build.
- [x] 7.3 Add sync status display (last synced time, sync-in-progress indicator, error message). Verify build.
- [x] 7.4 Add localized strings for all new UI elements to `Localizable.csv` and run `rake l10n`. Verify build.

## 8. Watch Connectivity Compatibility

- [x] 8.1 Verify that memos arriving via WatchConnectivity are correctly inserted into the CloudKit-enabled store and sync to other devices. When audio sync is on, populate `audioData` for watch-originated memos. Verify build.

## 9. Testing & Verification

- [ ] 9.1 Test enable/disable sync toggle — verify local data is preserved when toggling off. (manual test)
- [ ] 9.2 Test creating a memo on one device and verifying text appears on another. (manual test)
- [ ] 9.3 Test audio sync on: verify audio playback works on synced device. (manual test)
- [ ] 9.4 Test audio sync off: verify synced memos hide audio player correctly. (manual test)
- [x] 9.5 Run full test suite: 146 tests, 0 failures. TEST SUCCEEDED.
