## 1. Project Configuration

- [x] 1.1 Add `NSSupportsLiveActivities = YES` to `Resources/Info.plist` and update `project.yml` to include `Shared/LiveActivity/` sources in both the `Murmurs` and `MurmursWidget` targets. Regenerate with `xcodegen`. Verify: `xcodebuild build -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5`

## 2. Activity Attributes Model

- [x] 2.1 Create `Shared/LiveActivity/RecordingActivityAttributes.swift` defining `RecordingActivityAttributes: ActivityAttributes` with `ContentState` containing `recordedTime: Int` (seconds), `isPaused: Bool`, and `canPause: Bool`. Verify: build succeeds for both Murmurs and MurmursWidget schemes.

## 3. Live Activity Manager

- [x] 3.1 Create `Shared/LiveActivity/LiveActivityManager.swift` with a class that manages the Activity lifecycle: `startActivity(canPause:)`, `updateActivity(recordedTime:isPaused:)`, `endActivity(dismissed:)`. Use `Activity<RecordingActivityAttributes>.request()` to start and `activity.update()` to push state. Verify: `xcodebuild build -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5`

## 4. Live Activity UI (Widget Extension)

- [x] 4.1 Create `WatchWidget/RecordingLiveActivity.swift` (in the MurmursWidget target) implementing `Widget` protocol with `ActivityConfiguration` for `RecordingActivityAttributes`. Implement compact leading (microphone icon), compact trailing (MM:SS time), and minimal (recording dot) presentations. Verify: `xcodebuild build -project Murmurs.xcodeproj -scheme MurmursWidget -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5`

- [x] 4.2 Implement the expanded Dynamic Island view in `RecordingLiveActivity.swift`: show recording duration, state indicator (red dot for recording / pause icon for paused), pause/resume button (conditionally visible based on `canPause`), and stop button. Use `Button(intent:)` with App Intents for interactivity. Verify: build succeeds.

- [x] 4.3 Add the `RecordingLiveActivity` to the existing `WidgetBundle` in the MurmursWidget target so both the accessory widget and Live Activity are registered. Verify: build succeeds.

## 5. App Intents for Interactive Controls

- [x] 5.1 Create `Shared/LiveActivity/RecordingIntents.swift` with two App Intents: `TogglePauseRecordingIntent` (calls `AudioRecorder.shared.pauseRecording()` or `resumeRecording()`) and `StopRecordingIntent` (calls `AudioRecorder.shared.stopRecording()`). Both intents must conform to `LiveActivityIntent`. Verify: `xcodebuild build -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5`

## 6. Integration with Recording Flow

- [x] 6.1 In `RecordingViewModel.swift`, call `LiveActivityManager.shared.startActivity(canPause:)` after `recorder.startRecording()` succeeds. Pass `canPause` based on whether AVAudioRecorder mode is used. Verify: build succeeds.

- [x] 6.2 In `RecordingViewModel.swift` or `AudioRecorder.swift`, propagate recording state updates (time tick, pause, resume) to `LiveActivityManager.shared.updateActivity(recordedTime:isPaused:)` on each timer tick. Verify: build succeeds.

- [x] 6.3 In `RecordingViewModel.swift`, call `LiveActivityManager.shared.endActivity(dismissed: false)` when recording completes successfully, and `endActivity(dismissed: true)` when recording is terminated/cancelled. Verify: build succeeds.

## 7. Deep Link Handling

- [x] 7.1 Configure the Live Activity widget URL to use `murmurs://record` (the existing URL scheme). Verify that tapping the Dynamic Island opens the app to the recording view — this is handled by the existing `openURL` handler in `AppState`. Verify: build succeeds.

## 8. Final Verification

- [x] 8.1 Run full build for all affected schemes: Murmurs, MurmursWidget. Verify no warnings related to ActivityKit. Run `xcodebuild build -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5`
