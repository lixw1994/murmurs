## 1. Localization

- [x] 1.1 Add localization keys to `Localizable.csv`: `pause` / "Pause" / "暂停", `resume` / "Resume" / "继续", `continue_recording` / "Continue Recording" / "继续录音", `merging_audio` / "Merging audio..." / "正在合并音频...". Run `rake l10n` then verify build.

## 2. Recording Pause/Resume

- [x] 2.1 Add pause/resume support to `AudioRecorder`: add `@Published var isPaused = false` state. Add `pauseRecording()` method that calls `recorder.pause()` and sets `isPaused = true`, stops the monitoring timer. Add `resumeRecording()` method that calls `recorder.record()`, sets `isPaused = false`, resumes the timer. Only available when `audioEngine == nil` (non-engine mode). Verify: build.

- [x] 2.2 Add `canPause` published property to `AudioRecorder`: returns `true` when recording with AVAudioRecorder (not AVAudioEngine). Expose this so UI can conditionally show pause button. Verify: build.

- [x] 2.3 Update `RecordingView` to show pause/resume button: when `recorder.isRecording && recorder.canPause`, show a pause button next to the stop button. When `recorder.isPaused`, change button to resume icon. Wire button to call `recorder.pauseRecording()` / `recorder.resumeRecording()`. Verify: build.

## 3. Audio Merge Utility

- [x] 3.1 Add `FileHelper.mergeAudioFiles(original:append:) async throws -> URL` method: use `AVMutableComposition` to load both audio files, create composition tracks, insert time ranges, export via `AVAssetExportSession` with `.m4aAudio` preset to a new file. Return the merged file URL. Delete the temporary append file after merge. Verify: build.

## 4. Append Recording Flow

- [x] 4.1 Add `.appendRecording(MemoEntity)` case to `AppState.SheetType` (or equivalent sheet enum). Wire it in `MainView` to present `RecordingView` in append mode. Verify: build.

- [x] 4.2 Add "Continue Recording" menu item to `TimelineEntryView` context menu: show for all memos (with or without audio). On tap, set `appState.activeSheet = .appendRecording(memo)`. Verify: build.

- [x] 4.3 Add append completion handler to `TimelineViewModel`: `appendRecording(to memo: MemoEntity, voiceURL: URL, transcribedText: String?)`. This method should: (a) if memo has existing audio, call `FileHelper.mergeAudioFiles` and update `memo.file` and `memo.duration`; (b) if no existing audio, move file via `FileHelper.moveAudioFile` and set `memo.file` and `memo.duration`; (c) append transcribed text to `memo.content` with newline separator; (d) set `memo.polishedContent = nil` and `memo.title = nil`; (e) set `memo.updatedAt = Date()`; (f) save context and post `.memoInserted` notification. Verify: build.

- [x] 4.4 Wire `RecordingView` append mode: when opened with `.appendRecording(memo)`, after recording completes and optional transcription, call the append handler instead of creating a new memo. Verify: build.

## 5. Verification

- [x] 5.1 Run full test suite to confirm no regressions. Verify: `xcodebuild test -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20`
