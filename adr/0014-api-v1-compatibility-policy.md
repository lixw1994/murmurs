# ADR-0014: Keep /api/v1 backward compatible and enforce it from the contract

- Status: accepted
- Date: 2026-09-28
- Supersedes: —
- Deciders: project owner, Tech Lead

## Context and Problem Statement

Native iOS, watchOS, and Android clients call `/api/v1` (ADR-0004), and old app versions stay installed because users cannot be forced to update. The web client ships together with the server, but native clients do not. The API contract is generated from code and committed (ADR-0010). The project needs a rule for which API changes are allowed within `v1`, and a way to enforce that rule mechanically instead of relying on review.

## Considered Options

- Additive-only `v1`: allow new endpoints, new optional request fields, and new response fields; reject removals, type changes, and new required inputs; enforce this by diffing the contract against the main branch in CI; ship incompatible changes as `/api/v2` endpoints or a deprecate-then-remove cycle once old clients are gone
- Minimum-client-version gating: allow breaking changes and force clients below a minimum version to update
- Review-only discipline without automated checks

## Decision Outcome

Chosen option: "Additive-only v1 enforced from the contract", because it protects installed clients without a forced-update mechanism, and an automated `oasdiff breaking` check against the main branch's `contract/openapi.json` catches violations that review would miss.

### Consequences

- Good, because any installed client version keeps working against the current server.
- Good, because the rule is checked in CI on every pull request that touches the API.
- Bad, because API mistakes cannot simply be fixed in place; they stay in `v1` until a deprecation cycle or a `v2` endpoint replaces them.
- Bad, because clients must tolerate unknown response fields (generated clients ignore them by default).
- Follow-up: a forced-update mechanism may still be needed later for security fixes. It is not introduced here.
