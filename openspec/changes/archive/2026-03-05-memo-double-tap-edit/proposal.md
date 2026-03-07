## Why

Currently editing a memo requires navigating through the context menu or the "..." menu, which is slow for a frequent action. Double-tap is a natural, discoverable gesture for entering edit mode. Additionally, the edit view doesn't auto-focus the text field, forcing users to tap again before they can type.

## What Changes

- Add double-tap gesture on `TimelineEntryView` to open the edit sheet (same as the existing edit button)
- Add `@FocusState` to `MemoEditView` so the text editor auto-focuses and keyboard appears on presentation
- Ensure both entry points (double-tap and menu edit button) result in keyboard auto-showing

## Capabilities

### New Capabilities
- `memo-double-tap-edit`: Double-tap gesture on timeline entries to enter edit mode, with auto-focused text editor

### Modified Capabilities

## Impact

- **UI**: `TimelineEntryView` gains a double-tap gesture; `MemoEditView` gains `@FocusState` auto-focus
- **No data model changes**
- **No new dependencies**
