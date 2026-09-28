# ADR-0006: Process memos with Cloudflare Workflows

- Status: accepted
- Date: 2026-09-28
- Supersedes: —
- Deciders: project owner, Tech Lead

## Context and Problem Statement

After audio is uploaded, each memo goes through several steps: transcribe each audio segment, optionally polish, generate a title, write the results back to the user's Durable Object, and record usage. Each step calls external AI providers that can fail or rate-limit, and failures must be retryable without redoing completed steps.

## Considered Options

- Cloudflare Workflows: one durable workflow instance per memo, with `step.do` for each stage
- Cloudflare Queues with hand-chained messages per stage
- Inline processing in the upload request

## Decision Outcome

Chosen option: "Cloudflare Workflows", because each step is persisted and retried independently, instance status can be inspected, and no hand-written chaining or idempotency bookkeeping is needed between stages.

### Consequences

- Good, because a failed title step does not repeat a successful transcription.
- Good, because pipeline progress is observable per memo.
- Bad, because the pipeline depends on Workflows-specific APIs and limits (step count, duration, payload size), which must be verified before P2.
- Follow-up: record per-segment transcription so long recordings stay under provider file limits; a cron trigger re-queues memos stuck in `failed`.
