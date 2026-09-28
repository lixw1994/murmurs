# ADR Review Manifest

## ADR Review Completed

- Date: 2026-09-28
- Reviewer: Tech Lead
- Change: monorepo-and-server-skeleton

## In-Force ADR Context Reviewed

- adr/0001-native-clients-per-platform.md - defines the apple/, android/, web/, desktop/ areas this change starts creating
- adr/0002-thick-server-thin-clients.md - the API skeleton is the first server surface; no business logic moves yet
- adr/0003-cloudflare-as-backend-platform.md - Worker, D1, and wrangler environments
- adr/0004-single-worker-from-react-tanstarter.md - template reuse, Hono at /api/v1 via a catch-all route, native clients use only /api/v1, auth follow-up
- adr/0007-swiftui-first-with-uikit-bridging.md - unaffected; the Apple code moves unchanged
- adr/0008-minimum-ios-18-watchos-11.md - deployment targets preserved through the move
- adr/0010-openapi-contract-with-generated-clients.md - committed contract/openapi.json with a drift check; client generation deferred
- adr/0011-authentication-apple-google-email-otp.md - Better Auth kept but with every provider disabled until the auth change
- adr/0013-monorepo-in-existing-repository.md - layout, l10n/ as the single localization source, CI per area
- adr/0005, 0006, 0009, 0012 - reviewed; not affected by this change (sync, pipeline, offline model, billing come later)

## Repository-Level ADRs Created

- adr/0014-api-v1-compatibility-policy.md - /api/v1 is additive-only and enforced by an oasdiff breaking check against the main branch's contract

## Notes

- OpenAPI 3.0.3, the Vitest Workers pool, the CSV `platforms` column, and `%{n}` web interpolation are implementation choices recorded in design.md; they are not durable enough for ADRs.
