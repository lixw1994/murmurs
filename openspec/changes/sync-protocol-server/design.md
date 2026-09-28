## Context

ADR-0005 fixes the approach: one Durable Object per account with SQLite storage, a custom push/pull protocol, row-level last-write-wins on `updatedAt` with a device-id tie-break, soft deletes, and WebSocket change notifications. ADR-0009 keeps native clients offline-first. `/api/v1` already has bearer sessions (`requireSession`), a contract with coverage and breaking-change checks, and Vitest on the Workers pool. The Worker entry (`src/server-entry.ts`) is TanStack Start's; it can export additional classes.

Verified in the installed toolchain (2026-09-28): the workers types expose `DurableObjectNamespace.getByName`, `ctx.acceptWebSocket`/`getWebSockets`, and `webSocketMessage` (hibernation API); wrangler supports `new_sqlite_classes` migrations; `@cloudflare/vitest-pool-workers` provides `runInDurableObject`; `drizzle-orm` 0.45 has a `durable-sqlite` driver, whose drizzle-kit migrations import `.sql` files as text.

## Goals / Non-Goals

**Goals:** a correct, well-tested server implementation of the protocol, with executable fixtures that clients can reuse, deployed to staging.

**Non-Goals:** client engines, P2 pipeline fields, tombstone purging, production deploy (see proposal).

## Decisions

### D1. One generic `records` table per Durable Object, not one table per type

```sql
CREATE TABLE records (
  type TEXT NOT NULL, id TEXT NOT NULL,
  fields TEXT,                 -- JSON; NULL for tombstones
  updated_at INTEGER NOT NULL, deleted_at INTEGER,
  device_id TEXT NOT NULL, version INTEGER NOT NULL,
  PRIMARY KEY (type, id)
);
CREATE INDEX records_version ON records (version);
CREATE TABLE meta (key TEXT PRIMARY KEY, value INTEGER NOT NULL);  -- 'version'
```

The protocol treats every type the same way (merge, version, tombstone, pull). Field schemas are enforced at the API boundary with zod. So the storage needs no per-type columns, adding a type or field needs no storage migration, and one version index serves pulls. The server never queries by field content in P1. P2 updates memo fields by id, which JSON handles.

*Alternative:* one table per type, defined with Drizzle's `durable-sqlite` driver, as the roadmap sketched. Rejected: every field change would need a DO migration; drizzle-kit's DO migrations import `.sql` files as text, which needs extra Vite configuration; and the merge logic would be duplicated or generated per table.

### D2. Hand-written, ordered DO migrations

`src/server/sync/migrations.ts` exports `[{ id: 1, sql: "…" }]`. `UserSyncDO`'s constructor runs pending migrations inside `ctx.blockConcurrencyWhile`, recording applied ids in a `_migrations` table. The list is append-only.

### D3. `UserSyncDO` with RPC methods; the Worker authenticates

The Worker's Hono routes authenticate the bearer session and then call `env.USER_SYNC.getByName(userId)`. Because the object is chosen by the authenticated user id, isolation holds by construction. The object exposes RPC methods: `push(deviceId, changes)`, `pull(since, limit)`, and `deleteAll()`. It also has `fetch()` for the WebSocket upgrade, which the Worker forwards after authentication. Validation (zod) happens in the Worker; the object receives typed, validated changes.

### D4. Merge algorithm (inside a single synchronous transaction)

```
now = Date.now()
for change in changes (request order):
  updatedAt = min(change.updatedAt, now + 5 min) > now + 5 min ? now : change.updatedAt   # clamp
  stored = SELECT … WHERE type, id
  wins = !stored || (updatedAt, deviceId) > (stored.updated_at, stored.device_id)
  if wins:
    version = ++meta.version
    UPSERT record (fields = deletedAt ? NULL : JSON(fields), …, version)
    result = { status: "applied", version }
  else:
    result = { status: "stale", version: stored.version }
if any applied: broadcast { type: "version", version: meta.version }
```

The whole loop runs in `ctx.storage.transactionSync`, so a batch is atomic and versions have no gaps. The comparison is a tuple comparison: `updatedAt`, then `deviceId` (JavaScript string `<`). Re-pushing an identical change compares equal, so it is stale and idempotent. The clamp is exactly "more than 5 minutes ahead → server time".

### D5. Wire format

- Timestamps in sync payloads are integer milliseconds (exact comparison). Other `/api/v1` payloads keep ISO strings.
- `POST /sync/push`: `{ deviceId, changes: [{ type, id, updatedAt, deletedAt, fields? }] }` → `{ version, results: [{ type, id, status, version }] }`. `fields` is required when `deletedAt` is null. The `changes` array is a discriminated union on `type`.
- `GET /sync/pull?since&limit` → `{ version, hasMore, changes: [{ type, id, version, updatedAt, deletedAt, deviceId, fields? }] }`.
- `GET /sync/ws`: documented in the contract as an operation with a `101` response. Messages are JSON text frames. The only server message is `{ "type": "version", "version": n }`; client messages are ignored.
- `contract/sync-protocol.md` restates these rules for client implementers and links to the fixtures.

### D6. WebSocket with hibernation

`fetch()` creates a `WebSocketPair`, calls `ctx.acceptWebSocket(server)`, sends the current version, and returns 101. `push` broadcasts with `ctx.getWebSockets()`. Hibernation keeps idle connections free of duration charges. The Worker route checks the session before forwarding, so unauthenticated upgrades get 401.

### D7. Fixtures and the test harness

Fixture file shape:

```json
{ "name": "…", "description": "…",
  "steps": [
    { "push": { "device": "a", "changes": [ … ] },
      "expect": { "status": 200, "results": [{ "status": "applied" }] } },
    { "pull": { "since": 0 }, "expect": { "changes": [ { "type": "memos", "id": "…", "fields": { … } } ] } } ] }
```

`expect` is a partial match: listed keys must match; absent keys are not checked. Symbolic ids (`"$m1"`) map to generated UUIDs per run. `web/test/sync-fixtures.test.ts` loads every `contract/sync-fixtures/*.json`, creates a fresh account per fixture, and replays the steps against the API. Vitest's `import.meta.glob` makes each file its own test case. WebSocket, isolation, clock, and deletion scenarios are covered by dedicated tests in `web/test/sync.test.ts`, because they need two accounts, sockets, or time control.

### D8. Account deletion

`DELETE /api/v1/me` calls `USER_SYNC.getByName(userId).deleteAll()` (which runs `ctx.storage.deleteAll()` and closes sockets) before deleting the user.

### D9. Configuration

`wrangler.toml` gets a `USER_SYNC` Durable Object binding and `[[migrations]] tag = "v1", new_sqlite_classes = ["UserSyncDO"]`. Bindings are repeated in `[env.staging]` and `[env.production]`; migrations are top level. `src/server-entry.ts` and `test/api-worker.ts` export `UserSyncDO`.

## Risks / Trade-offs

- [Client clocks decide winners] → Clamping stops fast clocks from winning forever, but a slow clock can still lose a legitimate edit. This is accepted for single-user multi-device use (ADR-0005). The fixtures pin the behavior, so a later switch to hybrid logical clocks is a deliberate protocol change.
- [One Durable Object per account serializes that account's writes] → Expected load per account is tiny. Batches of up to 500 keep request counts low.
- [JSON fields cannot be constrained in SQL] → All writes pass zod validation in the Worker, and the object is reachable only through the Worker.
- [Tombstones accumulate] → Deferred purge; the rows are small. Purging needs a rule for devices that stay offline longer than the retention period, and that belongs in its own change.
- [WebSocket through TanStack Start's catch-all route] → The route forwards the raw `Request`, and the 101 response passes through. This is verified in local dev and on staging.

## Migration Plan

1. Deploy staging (`pnpm --dir web deploy:staging`), which applies the Durable Object migration `v1`.
2. Exercise push, pull, the WebSocket, and deletion against staging with two sessions of one account.
3. Rollback: `wrangler rollback --env staging`. Durable Object data exists only for test accounts.

## Open Questions

- None blocking. HLC and tombstone purge are recorded as future protocol changes.
