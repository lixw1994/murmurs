# ADR-0016: Store synced records as JSON in one generic table per user Durable Object

- Status: accepted
- Date: 2026-09-28
- Supersedes: —
- Deciders: project owner, Tech Lead

## Context and Problem Statement

ADR-0005 places each account's journal in its own Durable Object with SQLite storage and a last-write-wins protocol that treats every record type the same way. The record types (memos, summaries, prompts, settings) and their fields will keep growing: P2 adds pipeline fields, and new features add settings and types. Durable Object schemas are migrated in the object's constructor, per object, at first access.

## Considered Options

- One generic `records(type, id, fields JSON, updated_at, deleted_at, device_id, version)` table, with per-type field schemas enforced in the Worker with zod
- One table per record type with typed columns (for example with Drizzle's `durable-sqlite` driver)

## Decision Outcome

Chosen option: "One generic records table", because the merge, versioning, tombstone, and pull logic is identical for every type. Adding a type or field then needs no storage migration across every account's object, and a single version index serves every pull.

### Consequences

- Good, because protocol logic is written once and field evolution is a schema change in the Worker, not a data migration.
- Good, because per-object migrations stay rare (structural changes only).
- Bad, because SQL cannot constrain or index field contents. Every write must pass the Worker's validation, and server-side queries by field (none in P1) need JSON functions or a dedicated table later.
- Follow-up: if a type needs indexed queries (for example full-text search on the server), add a derived table for it rather than changing `records`.
