## Why

Every later phase needs a user's journal to exist on the server and on all of their devices. The web timeline (P1c), the iOS sync engine (P1b), the memo pipeline (P2), and server-side exports (P3) all depend on it. ADR-0005 chose one Durable Object per account and a custom push/pull protocol with row-level last-write-wins. That protocol has no off-the-shelf implementation and is the highest-risk part of the architecture, so it comes first: server side and conformance fixtures now, clients in the next changes.

## What Changes

- **Sync protocol document**: `contract/sync-protocol.md` defines the synced record types, the push, pull, and WebSocket messages, the merge rule, tombstones, and clock handling.
- **Conformance fixtures**: `contract/sync-fixtures/*.json` are step-by-step scenarios with expected results. The server test suite runs all of them, and the iOS and Kotlin sync engines will run the same files later.
- **Per-account Durable Object** (`UserSyncDO`, SQLite storage): holds the account's memos, summaries, prompts, and settings, and assigns a monotonic version to every applied change.
- **Endpoints** (bearer-authenticated, additive to `/api/v1`):
  - `POST /sync/push` applies a batch of client changes with last-write-wins and reports each outcome.
  - `GET /sync/pull?since=` returns changes after a version, paginated.
  - `GET /sync/ws` is a WebSocket that announces the latest version on connect and after every applied change.
- **Account deletion** also deletes the account's synced data.
- Staging gets the Durable Object migration and deployment.

## Capabilities

### New Capabilities

- `sync-protocol`: server behavior for storing, merging, versioning, pulling, and announcing an account's synced records, including validation limits and conformance fixtures.

### Modified Capabilities

- `anonymous-accounts`: "Delete the account" also deletes the account's synced data.

## Non-goals

- Client sync engines: iOS is P1b; the web timeline is P1c.
- Audio, transcription status, and other memo pipeline fields (P2). Memo fields are the ones the apps edit today.
- Purging old tombstones. They are kept for now; a scheduled purge can come when data volume warrants it.
- Collaboration or sharing: data is single-owner (ADR-0005).
- Production deployment.

## Impact

- **Areas**: server (`web/src/server/sync/`, new API routes, `server-entry.ts` exports the Durable Object class), contract (new endpoints, `sync-protocol.md`, `sync-fixtures/`), docs. Roadmap phase P1.
- **Cloudflare**: a Durable Object namespace with SQLite storage (a `new_sqlite_classes` migration) on dev and staging.
- **Contract**: additive only.
- **ADR**: ADR-0005 governs the protocol; no new ADR is expected unless design changes a durable choice.
