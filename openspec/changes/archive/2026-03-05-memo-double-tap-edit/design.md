## Context

`TimelineEntryView` currently has a single-tap gesture for multi-select mode. `MemoEditView` uses `MyTextView` (a UITextView wrapper) but has no `@FocusState`. The project already uses `@FocusState` in `QuickMemoView` with `.onAppear { focused = true }` as the established pattern.

## Goals / Non-Goals

**Goals:**
- Add double-tap gesture to open edit sheet
- Auto-focus text editor when edit sheet appears

**Non-Goals:**
- Changing the existing single-tap or context menu behavior
- Modifying MyTextView's UIViewRepresentable implementation

## Decisions

### 1. Use `.onTapGesture(count: 2)` for double-tap

Add a double-tap gesture to `TimelineEntryView`. The existing single-tap (for multi-select) must be ordered after the double-tap to avoid gesture conflicts — SwiftUI resolves higher-count tap gestures first.

### 2. Use `@FocusState` with `MyTextView`

`MyTextView` is a `UIViewRepresentable` wrapping `UITextView`. Since `@FocusState` works with `UIViewRepresentable` views that properly implement `becomeFirstResponder`, we add `@FocusState` to `MemoEditView` and bind it via `.focused()`. If `MyTextView` doesn't support the `focused` modifier natively, we call `becomeFirstResponder()` directly inside the UIViewRepresentable via coordination.

## Risks / Trade-offs

- **[Gesture conflict]** → Double-tap and single-tap on the same view. Mitigation: SwiftUI naturally waits to disambiguate; place double-tap before single-tap in modifier chain.
