# ADR Review Manifest

## ADR Review Completed

- Date: 2026-09-28
- Reviewer: Tech Lead
- Change: sync-protocol-server

## In-Force ADR Context Reviewed

- adr/0002-thick-server-thin-clients.md - merge rules live on the server; clients replay fixtures
- adr/0003-cloudflare-as-backend-platform.md - Durable Objects with SQLite storage
- adr/0004-single-worker-from-react-tanstarter.md - the Durable Object class is exported from the same Worker; native clients use /api/v1 only
- adr/0005-per-user-durable-object-with-custom-sync.md - the governing decision; implemented as specified (row LWW, device-id tie-break, soft delete, WebSocket notifications, conformance fixtures, clock clamping)
- adr/0009-offline-first-native-online-first-web.md - push/pull with cursors supports offline native clients; the web uses pull plus WebSocket
- adr/0010-openapi-contract-with-generated-clients.md - sync endpoints are part of the contract; semantics are pinned by fixtures
- adr/0014-api-v1-compatibility-policy.md - new endpoints are additive
- adr/0015-anonymous-accounts-with-recovery-codes.md - the account userId names the Durable Object; account deletion now deletes synced data
- adr/0001, 0006, 0007, 0008, 0011 (superseded), 0012, 0013 - reviewed; not affected

## Repository-Level ADRs Created

- adr/0016-generic-json-records-in-user-sync-do.md - synced records are stored as JSON in one generic table per user Durable Object, with field schemas enforced in the Worker

## Notes

- Millisecond timestamps in sync payloads, hand-written Durable Object migrations, and the fixture format are implementation details in design.md.
