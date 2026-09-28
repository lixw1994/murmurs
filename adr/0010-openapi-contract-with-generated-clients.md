# ADR-0010: Define the API as an OpenAPI contract and generate client code

- Status: accepted
- Date: 2026-09-28
- Supersedes: —
- Deciders: project owner, Tech Lead

## Context and Problem Statement

Swift, Kotlin, and TypeScript clients all call `/api/v1` (ADR-0001, ADR-0004). Hand-written models on each platform drift from the server and from each other.

## Considered Options

- Define routes with zod in Hono (`@hono/zod-openapi`), export `contract/openapi.json`, and generate clients: `swift-openapi-generator`, `openapi-generator` (Kotlin), and zod types or `openapi-typescript` (TypeScript)
- Hand-write request and response models per platform
- Kotlin Multiplatform for shared models between Android and iOS

## Decision Outcome

Chosen option: "zod → OpenAPI → generated clients", because the server schema becomes the single source of truth, drift is caught at build time, and no shared runtime is imposed on the Swift codebase.

### Consequences

- Good, because a schema change surfaces as compile errors on every client.
- Bad, because generated code and generator tooling become build dependencies.
- Bad, because the sync payloads (ADR-0005) also need conformance fixtures, since types alone do not guarantee semantics.
- Follow-up: commit `contract/openapi.json`, and have CI fail when it is out of date with the server code.
