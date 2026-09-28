# ADR-0005: Store journal data in one Durable Object per user with a custom sync protocol

- Status: accepted
- Date: 2026-09-28
- Supersedes: —
- Deciders: project owner, Tech Lead

## Context and Problem Statement

Journal data (memos, summaries, prompts, settings) must sync across a user's devices and support offline edits on native clients (ADR-0009). Data is owned by a single user with no collaboration, and the model has four synced tables. On Cloudflare (ADR-0003), Postgres-based sync engines are not available.

## Considered Options

- One Durable Object per user (SQLite storage) as the source of truth, with a custom push/pull protocol, row-level last-write-wins, and hibernatable WebSocket change notifications
- LiveStore with its Cloudflare Durable Object sync backend (event-sourced)
- PowerSync or ElectricSQL with an external Postgres
- D1 as a shared database with per-row ownership checks

## Decision Outcome

Chosen option: "Per-user Durable Object with custom sync", because single-owner data needs only row-level LWW. That is a small, fully controlled protocol, and per-user objects give isolation by construction, strong consistency per user, and built-in WebSocket fan-out.

### Consequences

- Good, because a user's data cannot leak through a missing ownership check.
- Good, because the protocol is small and has no third-party sync dependency.
- Bad, because the sync engine is custom code and the highest-risk part of the system; it is implemented and tested on three client platforms.
- Bad, because LWW keyed on client `updated_at` is sensitive to device clock skew.
- Bad, because cross-user queries (analytics, admin) cannot read journal data directly; global data lives in D1.
- Follow-up: publish `contract/sync-protocol.md` and conformance fixtures that server, Swift, and Kotlin must pass; clamp future timestamps on the server, and adopt HLC if skew proves to be a problem.
