## Why

The target architecture (ADR-0001..0013) needs a server and several clients that change together, but today the repository holds only a standalone Swift app at its root. Before sync, the memo pipeline, or new clients can be built, the repository needs its monorepo layout (ADR-0013). It also needs a deployable Cloudflare Worker that exposes a versioned API (ADR-0003, ADR-0004) and an API contract that clients can generate code from (ADR-0010). This is roadmap phase **P0**, excluding sign-in.

## What Changes

- **BREAKING (developer workflow)**: move the Swift project (`project.yml`, `Sources/`, `Shared/`, `Watch/`, `WatchWidget/`, `Packages/`, `Resources/`, `Tests/`, `SnapshotTests/`, `fastlane/`, and the Ruby tooling) under `apple/`. The iOS/watchOS app behaves the same; build commands change to run from `apple/`.
- Move `Localizable.csv` and the generator to `l10n/`. The generator keeps producing Swift sources and `.strings`, and also emits i18next JSON (`en`, `zh-Hans`) for the web.
- Create `web/` from the `react-tanstarter` template: rename it to Murmurs, give it its own D1 database and dev/staging/prod environments, and switch D1 schema management from `db:push` to generated migrations. Remove the template demo pages. Disable every sign-in provider and sign-up (sign-in arrives in a follow-up change).
- Mount a Hono application at `/api/v1/*` inside the Worker with `GET /api/v1/health` as its first endpoint. The template's `/api/auth/*` route remains but has no providers enabled.
- Generate `contract/openapi.json` from the API's zod route definitions, commit it, and fail verification when it is out of date. Native builds read this committed file, so they do not need the web toolchain.
- Detect breaking API changes: CI compares the contract in a change against the contract on the main branch and fails on backward-incompatible changes to `/api/v1`. Native apps cannot be force-updated, so old versions keep calling the API (ADR-0004).
- Set up a test runner for `web/` server code so later changes (sync, pipeline) can add tests.
- Update CLAUDE.md, README.md, `openspec/config.yaml`, `docs/architecture.md`, CI, and fastlane for the new paths.

## Capabilities

### New Capabilities

- `repository-layout`: the monorepo directories, what each owns, and the build and verification entry point each area provides.
- `localization-pipeline`: one CSV source generates localized strings for the Apple app and the web app, with consistent keys and languages.
- `api-foundation`: the versioned `/api/v1` HTTP surface of the Worker, including the health endpoint, the JSON error format, and per-environment deployment.
- `api-contract`: the OpenAPI document generated from the server code, where it is published, how drift between code and contract is detected, and how breaking changes to `/api/v1` are rejected.

### Modified Capabilities

None. Existing iOS/watchOS capabilities keep their behavior; only file locations change.

## Non-goals

- Sign-in of any kind: Better Auth providers, bearer tokens, the iOS `AuthService`, and `/api/v1/me` are left to the follow-up auth change.
- Sync, Durable Objects, R2 audio, and the memo pipeline (P1, P2).
- Web product UI beyond a placeholder landing page (P3).
- Generating Swift or Kotlin clients from the contract. This change only produces and guards the contract; client generation starts when a client first calls the API.
- `android/` and `desktop/` directories. They are created in P5 and P6.
- Choosing the production domain. Deployment uses Cloudflare-provided hostnames until the domain is decided.

## Impact

- **Areas**: apple (paths only), web (new), contract (new), l10n (new), docs and tooling. Roadmap phase P0.
- **Developer workflow**: `xcodegen`, `xcodebuild`, `bundle exec fastlane`, and `rake l10n` run from their new directories. CI (`.github/workflows/run-unit-tests.yml`) and CLAUDE.md verification commands change.
- **New dependencies (web)**: the template's stack (TanStack Start, Vite, Better Auth, Drizzle, wrangler), plus `hono` and `@hono/zod-openapi`, and a test runner chosen in design.
- **New CI tooling**: an OpenAPI breaking-change checker (for example `oasdiff`), chosen in design. The OpenAPI version emitted (3.0 or 3.1) is also chosen in design, based on Swift and Kotlin generator compatibility.
- **Cloudflare resources**: a new D1 database per environment. The template's D1 database, domain, and `.env*` secrets are not reused.
- **No runtime change** for the iOS/watchOS app.
