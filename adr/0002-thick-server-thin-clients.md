# ADR-0002: Keep business logic on the server; clients stay thin

- Status: accepted
- Date: 2026-09-28
- Supersedes: —
- Deciders: project owner, Tech Lead

## Context and Problem Statement

In the current app, transcription (Whisper), AI polish, titles, summaries, usage accounting, premium limits, and the Readwise integration all run on the iOS client, and users may supply their own OpenAI-compatible server and API key. With several native clients (ADR-0001), each piece of client-side logic would be implemented and maintained once per platform, and model API keys would ship to devices.

## Considered Options

- Server owns transcription, AI, quotas, and integrations; clients record, upload, store locally, display, and edit
- Keep logic on each client and share only data sync

## Decision Outcome

Chosen option: "Server owns the logic", because it is written once for all platforms, keeps provider keys off devices, and lets quotas be enforced centrally.

### Consequences

- Good, because a new client only needs UI, recording, local storage, upload, and a sync client.
- Good, because models and providers can change without shipping app updates.
- Bad, because transcription and AI features require connectivity; offline memos are processed after reconnecting.
- Bad, because server AI cost is borne by the product and must be covered by pricing (ADR-0012).
- Follow-up: remove the client `OpenAIClient`, client Readwise, `UsageEntity`, and the custom-server / bring-your-own-key settings. On-device transcription remains as a live preview and a privacy mode.
