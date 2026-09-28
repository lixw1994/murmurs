## 1. Protocol definition

- [ ] 1.1 Write `contract/sync-protocol.md` (record types and fields, push/pull/ws messages, merge rule, tombstones, clock clamp, fixtures). Verify: links resolve; matches the `sync-protocol` spec
- [ ] 1.2 Write fixtures in `contract/sync-fixtures/`: basic push and pull, newer wins, older stale, device-id tie-break, idempotent re-push, tombstone, resurrect, pagination, unknown field, invalid batch, batch limit. Verify: every file parses as JSON

## 2. Durable Object

- [ ] 2.1 Zod schemas for record types and push/pull payloads in `src/server/sync/schema.ts`. Verify: `pnpm --dir web check`
- [ ] 2.2 `src/server/sync/migrations.ts` and `UserSyncDO` (migrations in the constructor, `push` with the transactional merge and clock clamp, `pull`, `deleteAll`, WebSocket `fetch` and broadcast). Verify: `pnpm --dir web check`
- [ ] 2.3 wrangler `USER_SYNC` bindings (dev, staging, production) and `new_sqlite_classes` migration; export the class from `server-entry.ts` and `test/api-worker.ts`; `wrangler types`. Verify: `pnpm --dir web check && pnpm --dir web build`

## 3. API

- [ ] 3.1 Routes `POST /sync/push`, `GET /sync/pull`, `GET /sync/ws` (bearer; ws forwarded to the object). Verify: `pnpm --dir web check`
- [ ] 3.2 `DELETE /me` deletes the account's synced data. Verify: test 4.3

## 4. Tests

- [ ] 4.1 `test/sync-fixtures.test.ts` replays every fixture file. Verify: `pnpm --dir web test`
- [ ] 4.2 `test/sync.test.ts`: isolation between accounts, no session → 401, clock clamp, WebSocket notification to another socket and no message for stale pushes, pull limit capped at 1000. Verify: `pnpm --dir web test`
- [ ] 4.3 Account deletion removes synced records (`runInDurableObject` shows an empty table). Verify: `pnpm --dir web test`

## 5. Contract, deploy, docs

- [ ] 5.1 Regenerate the contract. Verify: drift passes; `BASE_REF=HEAD check-breaking.sh` passes; `check-generators.sh` passes for Swift and Kotlin
- [ ] 5.2 Deploy staging; with two sessions of one account, push from one, observe the WebSocket message on the other, pull, delete, and confirm the storage is empty. Verify: behavior matches the spec
- [ ] 5.3 Update `docs/architecture.md` (sync section), `docs/roadmap.md` (P1 progress), CLAUDE.md and `openspec/config.yaml` (sync in the current codebase). Verify: `openspec validate --all --strict`
- [ ] 5.4 Full verification sweep: web check, test, build; contract checks; specs
