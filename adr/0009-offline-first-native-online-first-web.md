# ADR-0009: Make native clients offline-first and the web client online-first

- Status: accepted
- Date: 2026-09-28
- Supersedes: —
- Deciders: project owner, Tech Lead

## Context and Problem Statement

Voice capture happens anywhere, often without connectivity, on phone and watch. Web and desktop sessions are typically online. Making the browser offline-first would require browser SQLite (OPFS / wa-sqlite) and multi-tab coordination.

## Considered Options

- Native offline-first (local database + sync engine + background upload queue); web online-first (REST + TanStack Query cache, refreshed by WebSocket notifications)
- Offline-first on every client, including the web
- Online-only everywhere

## Decision Outcome

Chosen option: "Native offline-first, web online-first", because recording must never depend on the network on mobile and watch, while the web gains little from offline support relative to its cost.

### Consequences

- Good, because the web client stays simple and the sync engine is needed only on Apple and Android.
- Bad, because the web and desktop cannot record or edit while offline.
- Bad, because there are two client data-access models to maintain.
- Follow-up: native clients use SwiftData / Room with `dirty`, `version`, and `deleted_at` fields, and background upload with `URLSession` background sessions or WorkManager.
