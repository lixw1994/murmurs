# ADR-0004: Serve web UI and API from one Worker built on react-tanstarter

- Status: accepted
- Date: 2026-09-28
- Supersedes: —
- Deciders: project owner, Tech Lead

## Context and Problem Statement

The owner's `react-tanstarter` template provides TanStack Start on Cloudflare Workers with D1 + Drizzle, Better Auth, i18next, shadcn/ui, admin user management, and a custom `src/server-entry.ts` that already wraps the Worker `fetch` handler. Native clients need a stable, versioned HTTP API. TanStack Start server functions are framework-internal RPC and are not a public contract. Durable Object classes and extra handlers must be exported from the Worker entry.

## Considered Options

- One Worker: TanStack Start for the web UI, with a Hono app mounted at `/api/v1/*` via a catch-all server route; Durable Object and Workflow classes exported from the existing custom entry
- Two Workers (Hono API and TanStack Start web) on one domain, connected by service bindings
- Use TanStack Start server functions as the API for all clients

## Decision Outcome

Chosen option: "One Worker", because the template's custom entry already solves the export problem, a single deploy is simpler at this stage, and keeping the API as a framework-independent Hono app keeps a later split cheap.

### Consequences

- Good, because there is one deploy, one domain, and same-origin cookies for the web.
- Good, because the template's auth, database, i18n, and admin features are reused.
- Bad, because web framework upgrades and API changes ship together, so an API regression can reach native clients that cannot be force-updated.
- Rule: native clients call only `/api/v1`; server functions serve the web UI only.
- Follow-up: add the Apple provider, the `bearer()` plugin, and email OTP; disable GitHub and Feishu; switch D1 from `db:push` to generated migrations.
