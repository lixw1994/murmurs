# ADR-0003: Run the backend on Cloudflare

- Status: accepted
- Date: 2026-09-28
- Supersedes: —
- Deciders: project owner, Tech Lead

## Context and Problem Statement

A backend is needed for accounts, multi-device sync, audio storage, a transcription/AI pipeline, billing webhooks, and integrations (ADR-0002). The project owner already maintains a Cloudflare Workers template (`react-tanstarter`) and prefers Cloudflare.

## Considered Options

- Cloudflare: Workers, Durable Objects, D1, R2, Workflows, AI Gateway, Workers AI
- Supabase: Postgres, Auth, Storage, Edge Functions, plus PowerSync for sync
- Self-hosted server

## Decision Outcome

Chosen option: "Cloudflare", because one platform provides compute, per-user stateful storage, relational storage, object storage without egress fees (suitable for audio), durable multi-step jobs, and a model gateway, and it matches the owner's existing template and experience.

### Consequences

- Good, because there is a single vendor, a single deploy target, and local emulation through `wrangler`.
- Good, because R2 has no egress fees for audio playback.
- Bad, because the team is tied to Workers runtime limits and Cloudflare-specific APIs (Durable Objects, Workflows).
- Bad, because Postgres-based sync engines such as PowerSync are not an option (see ADR-0005).
- Follow-up: separate dev, staging, and prod resources.
