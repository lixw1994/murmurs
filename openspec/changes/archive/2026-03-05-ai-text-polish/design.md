## Context

Murmurs currently supports voice transcription via Apple Speech and OpenAI Whisper. The transcribed text is stored in `MemoEntity.content`. The app already has an OpenAI-compatible chat API client (`OpenAIClient`) used for summarization, with streaming support. The live transcription feature (recently added) means more memos will have raw transcription text that benefits from refinement.

The existing summarization flow (`AddSummaryViewModel` → `OpenAIClient.summarize()`) demonstrates the established pattern for streaming LLM responses in the app.

## Goals / Non-Goals

**Goals:**
- Allow users to polish transcribed text using AI while preserving the original
- Display polished text prominently with original text available but de-emphasized
- Support the full lifecycle: polish → view both → delete polish → re-polish
- Reuse existing OpenAI infrastructure with minimal new code
- Stream polish results for responsive UX

**Non-Goals:**
- Custom polish prompts or tone selection (keep it simple, one-tap operation)
- Polishing non-transcribed (manually typed) content — though it will work on any content
- Offline polish capability
- Watch app support for polish
- Batch polish of multiple memos

## Decisions

### 1. Store polished text in a separate field (`polishedContent`)

**Decision**: Add `polishedContent: String?` to `MemoEntity` rather than overwriting `content`.

**Rationale**: The user explicitly wants to see both original and polished text simultaneously. Storing separately enables:
- Easy delete of polish (set to nil) without losing original
- Clear display logic: if `polishedContent != nil`, show it primary; show `content` secondary
- No data loss risk

**Alternative considered**: Store original in a new `originalContent` field and overwrite `content` — rejected because it changes the semantics of `content` for all existing code paths (export, summary, search).

### 2. Reuse `OpenAIClient.summarize()` with a polish prompt

**Decision**: Use the existing streaming chat completion method rather than adding a new API method.

**Rationale**: The summarize method already handles streaming, error handling, and token tracking. A polish operation is just a different prompt + the same streaming mechanism. We compose the polish prompt in the ViewModel layer.

**Alternative considered**: Add a dedicated `polish()` method to `AIClientProtocol` — rejected as it would add protocol surface area for what is essentially the same API call with a different prompt.

### 3. Polish state management in `TimelineViewModel`

**Decision**: Track polishing state (`polishingMemos: Set<MemoEntity>`) in `TimelineViewModel`, mirroring the pattern used for `transcribingMemos`.

**Rationale**: Consistent with the existing transcription flow. The timeline view already observes this ViewModel and can show loading states per-memo.

### 4. UI display strategy

**Decision**: In `TimelineEntryView`, when `polishedContent` is present:
- Show polished text as the primary content with normal styling
- Show original transcription below in a smaller, secondary style (e.g., lighter color, smaller font)
- Show a sparkle indicator to signal AI-polished content

**Rationale**: Users want polished text front-and-center but need access to the original for verification. A compact secondary display achieves both.

### 5. Polish prompt design

**Decision**: Use a simple, non-configurable system prompt that instructs the LLM to:
- Clean up grammar and punctuation
- Remove filler words
- Improve readability
- Preserve the original meaning and tone
- Output only the polished text (no explanations)
- Respond in the same language as the input

**Rationale**: Voice memos are personal and varied. The prompt should be neutral and meaning-preserving. Keeping it non-configurable reduces complexity.

## Risks / Trade-offs

- **[API cost]** → Each polish consumes chat API tokens. Mitigation: Uses the user's own API key (already configured for summarization); no additional cost to app operator.
- **[Model availability]** → Polish requires a configured and valid OpenAI-compatible server. Mitigation: Same requirement as summarization; share the "server not configured" error handling.
- **[SwiftData migration]** → Adding a new field to MemoEntity. Mitigation: Optional field with nil default — SwiftData handles lightweight migration automatically for additive changes.
- **[Meaning drift]** → AI polish could alter the intended meaning. Mitigation: Always show original text alongside; easy one-tap delete of polish; prompt explicitly instructs meaning preservation.
