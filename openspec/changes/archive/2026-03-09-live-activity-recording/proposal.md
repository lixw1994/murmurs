## Why

Recording is the core action in Murmurs. When users start recording and switch to another app, they lose visibility into recording status — they can't see elapsed time or quickly pause/resume without reopening Murmurs. Adding Live Activity (Dynamic Island) support surfaces recording state system-wide, matching the UX of Apple's native Voice Memos app and providing a significant differentiator over competitors like Voicenotes.

## What Changes

- Add a new Live Activity that activates when recording starts, showing elapsed time and recording status
- Display recording controls (pause/resume, stop) in the Dynamic Island expanded view
- Update the Live Activity in real-time as recording time progresses and pause state changes
- Dismiss the Live Activity when recording stops or is terminated
- Tapping the Live Activity or Dynamic Island opens Murmurs to the active recording view

## Non-goals

- Lock Screen Live Activity is out of scope for the initial implementation (focus on Dynamic Island)
- No Apple Watch Live Activity support (watchOS does not support ActivityKit Live Activities)
- No push-token-based updates — all updates are local since the app process is alive during recording
- No waveform visualization in the Dynamic Island (keep it simple: time + status)

## Capabilities

### New Capabilities
- `live-activity-recording`: Live Activity integration for audio recording, displaying recording duration and pause/resume state in the Dynamic Island with interactive controls

### Modified Capabilities
- `recording-pause-resume`: Minor integration point — recording state changes must now also trigger Live Activity updates

## Impact

- **New target**: A Widget Extension target for Live Activity (ActivityKit requires a widget extension bundle)
- **project.yml**: Add new `MurmursLiveActivity` target with ActivityKit capability
- **Info.plist**: Add `NSSupportsLiveActivities = YES` to main app
- **Shared/Recorder/AudioRecorder.swift**: Add Live Activity start/update/end calls at recording state transitions
- **Dependencies**: ActivityKit (system framework, no SPM package needed)
- **Deployment**: iOS 16.1+ for ActivityKit, but app already targets iOS 17.0+ so no change needed
