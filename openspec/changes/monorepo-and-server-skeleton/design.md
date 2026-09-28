## Context

The repository holds a standalone Swift app at its root (see `docs/architecture.md`). In-force ADRs fix the destination: native clients per platform (ADR-0001), one Cloudflare Worker built from `react-tanstarter` with a Hono API at `/api/v1` (ADR-0003, ADR-0004), an OpenAPI contract with generated clients (ADR-0010), and a monorepo in this repository (ADR-0013). This change builds the skeleton those later phases depend on, without sign-in, sync, or product features.

Verified facts this design relies on (checked 2026-09-28):

| Item | Fact |
|---|---|
| Template | TanStack Start 1.146 on Vite 8, `@cloudflare/vite-plugin`, custom `src/server-entry.ts` that wraps `fetch` and injects `env`, `db`, `auth`; Better Auth 1.4 with the Drizzle D1 adapter; i18next with nested `en.json` and `zh.json`; server routes via `createFileRoute(...){ server: { handlers } }` (see `routes/api/auth/$.ts`) |
| `@hono/zod-openapi` | 1.6.3; peer dependencies `zod ^4` (the template uses zod 4.3) and `hono >=4.10` (latest 4.13.10); can emit OpenAPI 3.0 (`getOpenAPIDocument`) or 3.1 (`getOpenAPI31Document`) |
| Test runner | `@cloudflare/vitest-pool-workers` 0.22.0 requires `vitest ^4.1`; `vitest` 4.1.11 accepts Vite `^6 \|\| ^7 \|\| ^8`; the latest `vitest` is 5.x and is incompatible |
| oasdiff | Go binary (the npm package named `oasdiff` is a placeholder); Homebrew 1.32.1; a GitHub Action exists |
| Local machine | Node 24, pnpm 10, Swift 6.4, Docker; no Java runtime; `wrangler` comes from the project devDependencies |
| Localization | `Localizable.csv` has 163 Apple keys (162 strings plus one InfoPlist key), `%@` and `%d` placeholders, literal `{{date}}` in prompt text, and section comment rows such as `# Plist #` |
| Legal pages | `html/*.html` are sources of pages hosted at `lixw1994.github.io/murmurs`; this repository does not serve them |
| `.gitignore` | Rules such as `fastlane/report.xml` and `*.xcodeproj/**` contain a slash, so they only match at the repository root and stop matching after the move |

## Goals / Non-Goals

**Goals:**
- Move the Swift project under `apple/` with no change to targets or app behavior.
- Keep one localization source that feeds Apple and web.
- Build and test a Worker locally that serves a placeholder web UI and `GET /api/v1/health`, with the shared error format.
- Commit an OpenAPI 3.0 contract; detect drift and breaking changes; prove that Swift and Kotlin generators accept it.
- Run CI per area on pull requests.

**Non-Goals:**
- Sign-in, sync, R2, Workflows, product UI, and client code generation in the apps (see proposal).
- Creating remote Cloudflare resources or deploying. The configuration and commands are prepared; the owner runs them with their account (see Migration Plan).

## Target layout

```text
.
├── apple/                 Swift project (moved as-is)
│   ├── project.yml  Sources/  Shared/  Watch/  WatchWidget/  Packages/
│   ├── Resources/  Tests/  SnapshotTests/  fastlane/  Gemfile  Gemfile.lock
├── web/                   react-tanstarter derivative (one Worker)
│   ├── src/server/api/    Hono app: routes, errors, openapi
│   ├── src/routes/api/v1/$.ts
│   ├── drizzle/           D1 migrations
│   ├── public/legal/      former html/
│   ├── scripts/           contract generation
│   └── test/              vitest-pool-workers tests
├── contract/
│   ├── openapi.json       generated, committed
│   ├── scripts/           check-drift.sh, check-breaking.sh, check-generators.sh
│   └── consumers/swift/   minimal SwiftPM package that runs swift-openapi-generator
├── l10n/
│   ├── Localizable.csv
│   └── generate           Ruby generator (former scripts/l10n)
├── Rakefile               `rake l10n` entry point
├── docs/  adr/  openspec/
│   └── docs/assets/       former Images/
└── .github/workflows/     apple.yml, web.yml, contract.yml, l10n.yml
```

## Decisions

### D1. Move with `git mv`, keep project-relative paths

Move the Swift project directories and the Ruby tooling (`Gemfile`, `Gemfile.lock`, `fastlane/`) into `apple/` with `git mv` to keep history. Paths inside `project.yml` are relative to `project.yml`, so they stay valid. The two cross-area references are changed: the l10n output path (D4) and the `.gitignore` rules, which become `apple/`-scoped or `**/`-prefixed patterns. `html/` moves to `web/public/legal/` and `Images/` to `docs/assets/`, so that the root holds only areas and project metadata.

*Alternative:* keep the Apple project at the root and add the other areas beside it. Rejected because ADR-0013 fixes the layout, and a root that mixes one platform's files with area directories hides ownership.

### D2. Web: strip the template to a placeholder and keep auth dormant

Copy the template without `.git`, `node_modules`, `.env*`, `.wrangler`, `dist`, `.tanstack`, or its agent files. Rename it to `murmurs`. Remove the demo and account routes (`(app)/*`, `(auth)/*`, `about`), the admin user management, and the auth UI components. Keep the root shell, the theme, the i18n setup, shadcn/ui, and a public landing page that shows the Murmurs name and a short description.

Keep Better Auth mounted at `/api/auth/*` with the D1 adapter and the `tanstackStartCookies` plugin, but with `emailAndPassword.enabled: false`, no social providers, and no generic OAuth. Sign-up and sign-in then fail by construction, and the follow-up auth change only adds providers. Remove the `VITE_ALLOW_*` flags and the admin email setting. Keep `BETTER_AUTH_SECRET` required.

*Alternative:* remove Better Auth entirely until the auth change. Rejected because its tables anchor the first D1 migration, and re-adding the wiring is more work than keeping it inert.

### D3. Environments, configuration, and D1 migrations

`wrangler.toml` defines the top level as local development and adds `[env.staging]` and `[env.production]`. Each environment has its own Worker name (`murmurs-staging`, `murmurs`), its own D1 binding, and an `ENVIRONMENT` variable (`development`, `staging`, `production`). Staging and production `database_id` values are filled in when the owner creates the databases. Until then they hold explicit `REPLACE_WITH_*` values, and deploying fails fast. No custom domain is configured, so deploys use `workers.dev`.

D1 schema changes use `drizzle-kit generate` (output `web/drizzle/`, set as `migrations_dir`) and `wrangler d1 migrations apply DB [--local | --env <env> --remote]`. The template's `db:push` scripts and the `d1-http` credentials block are removed. The first migration creates the Better Auth tables.

### D4. Localization: `platforms` column, generator in `l10n/`, web interpolation `%{n}`

`Localizable.csv` gains a `platforms` column after `comment`. Existing keys get `apple`, and web keys get `web` or `apple web`. The Ruby generator moves to `l10n/generate` and gains:

- a `--web DIR` output that writes `en.json` and `zh-Hans.json`. Keys are split on `.` into nested objects, so web keys use a `web.` namespace (for example `web.landing.title`), and a leaf-versus-parent collision fails generation.
- placeholder conversion for web: `%@`, `%d`, and positional `%n$@` / `%n$d` become `%{0}`, `%{1}`, … The web i18next configuration sets `interpolation.prefix = "%{"` and `suffix = "}"`, so literal `{{date}}` is never interpolated.
- validation: comment rows (`#…#`) are skipped; an empty or unknown `platforms` value fails; missing translations are reported per key and language; output is sorted and stable.

`rake l10n` at the repository root runs the generator with the Apple and web output paths. Web locale ids become `en` and `zh-Hans`, replacing the template's `zh`, so both platforms use the same language tags.

*Alternatives:* a key prefix convention instead of a column (rejected: it cannot express shared keys without renaming the 163 existing keys); escaping `{{` for i18next (rejected: i18next has no escape syntax for literal braces).

### D5. API: Hono mounted through a catch-all server route

`web/src/server/api/app.ts` builds an `OpenAPIHono` app with `basePath("/api/v1")`, typed bindings for the Worker `Env`, and:

- `GET /health` → `{ status: "ok", version, environment }`. `version` comes from `package.json` through the existing `__APP_VERSION__` define. `environment` comes from `ENVIRONMENT`.
- `defaultHook` → 400 `{ error: { code: "invalid_request", message, details: <zod issues> } }`.
- `notFound` → 404 `not_found`. `onError` → 500 `internal_error` with a generic message; the error is logged, never returned.
- a shared `ErrorResponse` schema registered as a component and referenced by every route's error responses.

`src/routes/api/v1/$.ts` forwards `GET`, `POST`, `PUT`, `PATCH`, and `DELETE` to `apiApp.fetch(request, context.env, executionCtx)`. The API module imports nothing from TanStack Start, so it can move to its own Worker later (ADR-0004).

### D6. Contract: OpenAPI 3.0.3, committed JSON, drift, breaking, and consumer checks

- **Version**: emit **3.0.3** with `getOpenAPIDocument`. `swift-openapi-generator` supports 3.0 and 3.1, but the Kotlin `openapi-generator`'s 3.1 support is incomplete, so 3.0 is the common denominator.
- **Generation**: `pnpm contract:generate` (in `web/`) runs `scripts/generate-contract.ts` with `tsx`. It imports the API app, calls `getOpenAPIDocument`, and writes `contract/openapi.json` as 2-space JSON with a trailing newline. Output order follows route registration, so it is deterministic.
- **Drift**: `contract/scripts/check-drift.sh` regenerates the contract into a temporary file and diffs it against the committed one. On mismatch it exits non-zero and prints `pnpm --dir web contract:generate`.
- **Breaking changes**: `contract/scripts/check-breaking.sh` runs `oasdiff breaking --fail-on ERR` between the main branch's contract (`git show origin/master:contract/openapi.json`) and the working copy. It uses a local `oasdiff` binary if present, otherwise the `tufin/oasdiff` Docker image. When the base has no contract yet (this change), it reports "no baseline" and passes. CI uses the same script.
- **Consumers**: `contract/scripts/check-generators.sh [swift|kotlin]` (default: both) (a) builds `contract/consumers/swift`, a SwiftPM package whose target uses the `swift-openapi-generator` build plugin with `openapi.json` symlinked from the contract, and (b) runs `openapitools/openapi-generator-cli` in Docker with `-g kotlin` into a temporary directory. Both must succeed.

*Alternative:* design-first (hand-written OpenAPI or TypeSpec). Rejected for this project: a single team changes server and clients in one pull request, so code-first with a committed artifact and CI checks gives the same guarantees with less ceremony.

### D7. Tests: Vitest 4 with the Workers pool

Add `vitest@^4.1` and `@cloudflare/vitest-pool-workers@0.22` with a `vitest.config.ts` that uses `wrangler.toml` (development environment). The first tests call `SELF.fetch` to cover `/api/v1/health`, 404 JSON for unknown API paths, and the 500 envelope (through a test-only route that throws, registered only in the test app factory). The same pool later runs Durable Object and D1 tests. `pnpm test` runs it.

### D8. CI: one workflow per area, with path filters

| Workflow | Triggers (pull request, and push to `master`) | Runner | Steps |
|---|---|---|---|
| `apple.yml` | `apple/**`, `l10n/**`; also push to `release/*` | macOS | bundle install, xcodegen, `bundle exec fastlane tests` in `apple/` |
| `web.yml` | `web/**`, `contract/**`, `l10n/**` | Ubuntu | pnpm install, `pnpm check`, `pnpm test`, `pnpm build`, `contract/scripts/check-drift.sh`, `check-breaking.sh` (fetches `master`) |
| `contract.yml` | `contract/**`, `web/src/server/api/**` | two jobs: macOS for Swift, Ubuntu for Kotlin (native Docker) | `contract/scripts/check-generators.sh swift` and `check-generators.sh kotlin` |
| `l10n.yml` | `l10n/**`, `Rakefile` | Ubuntu | `rake l10n`, then `git diff --exit-code` over the generated files |

The Fastlane `tests` lane device moves from iPhone 15 Pro to iPhone 17 Pro, matching the documented local command and current simulators.

## Risks / Trade-offs

- [Moving 250+ tracked files breaks tool caches and editor state] → Regenerate with `xcodegen` inside `apple/` and verify build, tests, and the Watch scheme before touching other areas.
- [`.gitignore` rules silently stop matching after the move] → Rewrite the root-anchored rules, and check that `git status` is clean after a build inside `apple/`.
- [vitest-pool-workers pins its own wrangler and Miniflare versions, which may lag the project's wrangler] → Pin `vitest@^4.1`. If the pool's runtime lacks a compatibility date that the project uses, align the date rather than the versions.
- [Docker-dependent checks (oasdiff fallback, Kotlin generator) fail where Docker is not running] → The scripts check Docker availability and fail with a clear message. CI runners provide Docker.
- [Placeholder `database_id` values could be committed and deployed by mistake] → They are syntactically invalid for wrangler, so deploy fails fast. The owner tasks replace them.
- [Web-only strings in the CSV grow it with keys the Apple app never uses] → `platforms` filtering keeps each output exact. CSV size is not a runtime cost.

## Migration Plan

No user data exists, so there is nothing to migrate. Rollout:

1. Land the change on `master`; developers re-run `xcodegen` inside `apple/`.
2. **Owner (needs a Cloudflare account)**: `wrangler d1 create murmurs-db-staging` and `murmurs-db-production`; put the IDs in `web/wrangler.toml`; `wrangler secret put BETTER_AUTH_SECRET --env staging` (and production); `pnpm --dir web db:migrate:staging`; `pnpm --dir web deploy:staging`; confirm that `/api/v1/health` reports `staging`. Then repeat for production.
3. Rollback: `wrangler rollback --env <env>` for the Worker; D1 has no data to lose.

## Open Questions

- The production domain remains undecided (roadmap). It is needed by the auth change, not by this one.
- Whether the Kotlin generator check should use a Java setup instead of Docker once `android/` exists and CI needs a JDK anyway.
