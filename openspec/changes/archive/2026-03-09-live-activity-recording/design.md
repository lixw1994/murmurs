## Context

Murmurs currently presents recording state exclusively within the `RecordingView` sheet. When users switch apps during recording, they lose all visibility into recording status. The app already supports background audio (`UIBackgroundModes: [audio]`), pause/resume via `AudioRecorder`, and has a WidgetKit extension target (`MurmursWidget`). iOS 17+ (our deployment target) fully supports ActivityKit Live Activities and Dynamic Island.

Key existing components:
- `AudioRecorder` — `@Published` properties: `isRecording`, `isPaused`, `recordedTime`
- `RecordingView` / `RecordingViewModel` — UI and orchestration
- `AppState` — controls `showRecording` sheet presentation
- `project.yml` — already has `MurmursWidget` target for accessory widgets

## Goals / Non-Goals

**Goals:**
- Show recording duration and status (recording/paused) in the Dynamic Island
- Allow pause/resume and stop from the Dynamic Island expanded view
- Automatically start the Live Activity when recording begins and dismiss it when recording ends
- Tapping the compact/minimal Dynamic Island opens Murmurs to the recording view

**Non-Goals:**
- Lock Screen Live Activity widget (can be added later)
- Waveform visualization in Dynamic Island (too complex for small surface)
- Apple Watch Live Activity (not supported by watchOS)
- Push-token-based remote updates (unnecessary — app process is alive during recording)

## Decisions

### 1. Reuse existing MurmursWidget target vs. new target

**Decision**: Add Live Activity to the existing `MurmursWidget` target.

**Rationale**: ActivityKit Live Activities are defined as `Widget` conformances within a widget extension bundle. The existing `MurmursWidget` target already provides this bundle. Adding a separate target would increase build complexity and app size with no benefit. Apple's documentation confirms multiple `Widget` types can coexist in one extension via `WidgetBundle`.

**Alternative considered**: New `MurmursLiveActivity` target — rejected because it adds unnecessary target overhead and requires its own bundle ID, provisioning profile, and entitlements.

### 2. Activity Attributes model location

**Decision**: Define `RecordingActivityAttributes` in a new file under `Shared/LiveActivity/` so it's accessible from both the main app (to start/update activities) and the widget extension (to render UI).

**Rationale**: Both the app and the widget extension need access to the same `ActivityAttributes` type. Placing it in `Shared/` follows the existing pattern for cross-target code.

### 3. Live Activity update mechanism

**Decision**: Use `Activity.update()` with a Timer-driven approach, updating the Live Activity every 1 second with the current `recordedTime` and `isPaused` state.

**Rationale**: The app process is always alive during recording (background audio mode). Local updates via `Activity.update()` are simple and reliable. No push notification infrastructure needed.

**Alternative considered**: Using `ActivityKit` push tokens — overkill since the app is foregrounded or in background audio mode during recording.

### 4. Interactive controls in Dynamic Island

**Decision**: Use App Intents (`LiveActivityIntent`) for pause/resume and stop buttons in the expanded Dynamic Island view.

**Rationale**: iOS 17+ supports interactive widgets via App Intents. This allows users to pause/resume and stop recording directly from the Dynamic Island without switching to the app. The intents will call through to `AudioRecorder.shared`.

### 5. Integration point in AudioRecorder

**Decision**: Create a new `LiveActivityManager` class that observes `AudioRecorder` state and manages the Activity lifecycle. Avoid modifying `AudioRecorder` internals directly.

**Rationale**: Keeps `AudioRecorder` focused on audio concerns. `LiveActivityManager` subscribes to recorder state changes and translates them to Activity updates. This follows the existing pattern of separating concerns (e.g., `AudioRecorder` doesn't know about UI).

**Files affected**:
- `Shared/LiveActivity/RecordingActivityAttributes.swift` — Activity data model
- `Shared/LiveActivity/LiveActivityManager.swift` — Activity lifecycle management
- `WatchWidget/` or `MurmursWidget/` — Live Activity UI views
- `Sources/Modules/Recording/RecordingViewModel.swift` — Start/stop LiveActivityManager
- `project.yml` — Add `NSSupportsLiveActivities` to Info.plist, add Shared/LiveActivity sources to widget target
- `Resources/Info.plist` — Add `NSSupportsLiveActivities = YES`

## Risks / Trade-offs

- **[Risk] Timer-based updates at 1s interval may drain battery** → Mitigation: 1s is the same cadence as the existing recording timer. The Live Activity update is a lightweight state push, not a re-render trigger.
- **[Risk] Widget extension and main app share no process memory** → Mitigation: Use `ActivityAttributes` / `ContentState` as the data contract. No shared memory needed — the main app pushes state via `Activity.update()`.
- **[Risk] Live Activity not dismissed if app crashes during recording** → Mitigation: ActivityKit automatically dismisses stale activities after 8 hours. We can also set a `dismissalPolicy` of `.after` with a reasonable timeout.
- **[Risk] AVAudioEngine mode (live transcription) doesn't support pause** → Mitigation: In engine mode, the Dynamic Island will show recording time and stop button only, no pause button. The `isPaused` state in ContentState controls button visibility.
- **[Trade-off] No Lock Screen widget initially** → Acceptable for v1. The Dynamic Island provides the primary glanceable surface. Lock Screen can be added as a follow-up.
