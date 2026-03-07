## Why

Live transcription produces raw speech-to-text output that often contains filler words, awkward phrasing, and punctuation issues. Users want cleaner, more readable text without losing the original meaning. An AI polish feature leverages the existing OpenAI-compatible chat API to refine transcribed content, making voice memos more useful for review, sharing, and export.

## What Changes

- Add a new `polishedContent` field to `MemoEntity` to store AI-polished text alongside the original transcription
- Add an "AI Polish" action in memo context menus and detail views, available when a memo has transcribed content
- Display polished text as the primary view when available, with the original transcription shown in a de-emphasized style
- Support deleting polished text (reverting to original) and re-polishing
- Stream polished text from the OpenAI chat API using the existing `OpenAIClient` infrastructure
- Show real-time streaming progress during polish operations

## Capabilities

### New Capabilities
- `ai-text-polish`: AI-powered text refinement for transcribed memo content, including storage of both original and polished text, polish/delete/re-polish lifecycle, and streaming UI feedback

### Modified Capabilities
- `live-transcription`: No requirement changes — live transcription behavior is unchanged. The polish feature operates on already-transcribed content regardless of transcription method.

## Impact

- **Data model**: `MemoEntity` gains a new optional `polishedContent: String?` field (SwiftData migration)
- **Services**: `OpenAIClient` / `AIClientProtocol` may need a new method or the existing `summarize` method can be reused with a polish-specific prompt
- **UI**: `TimelineEntryView` needs to display polished vs. original text; context menus gain polish/delete-polish actions
- **Dependencies**: No new dependencies — uses existing OpenAI chat API infrastructure
- **Config**: May reuse existing `aiModel` setting, or add a polish-specific model preference
