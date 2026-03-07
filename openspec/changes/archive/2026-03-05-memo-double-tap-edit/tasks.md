## 1. Double-tap gesture

- [x] 1.1 Add `.onTapGesture(count: 2)` to `TimelineEntryView` that opens `appState.activeSheet = .editMemo(memo)` when not in multi-select mode
- [x] 1.2 Ensure existing single-tap gesture for multi-select still works (order double-tap before single-tap)

## 2. Auto-focus text editor

- [x] 2.1 Add `autoFocus` parameter to `MyTextView` that calls `becomeFirstResponder()` on the UITextView
- [x] 2.2 Set `autoFocus: true` in `MemoEditView` so the keyboard auto-shows

## 3. Testing

- [x] 3.1 Verify double-tap opens edit sheet, single-tap still works for multi-select, and keyboard appears on edit
