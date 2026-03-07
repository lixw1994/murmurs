## 1. Data Model

- [x] 1.1 Add `polishedContent: String?` property to `MemoEntity` in `Sources/Persistence/MemoEntity.swift`
- [x] 1.2 Add a computed property `viewPolishedContent` (similar to `viewContent`) and a `hasPolishedContent` convenience property
- [x] 1.3 Update `MemoEntity` export-related code to prefer `polishedContent` over `content` when available

## 2. Polish Service

- [x] 2.1 Create a polish prompt constant (system prompt instructing the LLM to clean up grammar, remove filler words, preserve meaning, respond in same language, output only polished text)
- [x] 2.2 Add a `polish(_ text: String, model: OpenAIChatModel)` method to `OpenAIClient` (or compose using existing `summarize` method with polish prompt) that returns an `AsyncThrowingStream<String, Error>`

## 3. ViewModel Integration

- [x] 3.1 Add `polishingMemos: Set<MemoEntity>` and `polishFailedMemos: [MemoEntity: Error]` to `TimelineViewModel`
- [x] 3.2 Implement `polish(_ memo: MemoEntity)` in `TimelineViewModel` — streams result, saves `polishedContent`, handles errors
- [x] 3.3 Implement `deletePolish(_ memo: MemoEntity)` in `TimelineViewModel` — sets `polishedContent` to nil and saves
- [x] 3.4 Add server-configured guard check before starting polish (show error if server not set)

## 4. Timeline UI

- [x] 4.1 Update `TimelineEntryView` to display `polishedContent` as primary text with a sparkle indicator when available
- [x] 4.2 Show original `content` as secondary de-emphasized text (smaller font, lighter color) when `polishedContent` is present
- [x] 4.3 Show loading indicator on memo when polish is in progress (`polishingMemos` contains the memo)
- [x] 4.4 Add "AI Polish" context menu action (visible when memo has content and is not currently polishing)
- [x] 4.5 Add "Delete Polish" context menu action (visible when memo has `polishedContent`)
- [x] 4.6 Show error feedback when polish fails

## 5. Localization

- [x] 5.1 Add localization keys for new UI strings: AI Polish action, Delete Polish action, polish error messages, polishing progress indicator text
- [x] 5.2 Run `rake l10n` to regenerate `LocalizedKeys.swift`

## 6. Testing

- [x] 6.1 Add unit tests for `polish()` and `deletePolish()` in `TimelineViewModel` using mock `AIClientProtocol`
- [x] 6.2 Verify `MemoEntity.polishedContent` persistence round-trip in tests
