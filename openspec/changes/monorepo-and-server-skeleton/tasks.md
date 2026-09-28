## 1. Move the Apple project under apple/

- [ ] 1.1 `git mv` `project.yml`, `Sources/`, `Shared/`, `Watch/`, `WatchWidget/`, `Packages/`, `Resources/`, `Tests/`, `SnapshotTests/`, `fastlane/`, `Gemfile`, `Gemfile.lock` into `apple/`; move `Murmurs.xcodeproj` (tracked `Package.resolved`) with them. Verify: repository root has no Swift project files (`ls`)
- [ ] 1.2 Move `html/` → `web/public/legal/` and `Images/` → `docs/assets/`. Verify: `git status` shows renames only
- [ ] 1.3 Rewrite root-anchored `.gitignore` rules (`fastlane/*`, `*.xcodeproj/**` family) for `apple/`. Verify: after 1.4, `git status --short` shows no build or xcodeproj noise
- [ ] 1.4 Regenerate and build from `apple/`. Verify: `cd apple && xcodegen && xcodebuild build -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` → `** BUILD SUCCEEDED **`
- [ ] 1.5 Build the Watch scheme and run the unit tests from `apple/`. Verify: `xcodebuild build -scheme MurmursWatch -destination 'generic/platform=watchOS Simulator'` succeeds; `xcodebuild test ... -scheme Murmurs` passes
- [ ] 1.6 Update the Fastlane `tests` lane device to iPhone 17 Pro. Verify: `ruby -c apple/fastlane/Fastfile`

## 2. Localization pipeline in l10n/

- [ ] 2.1 `git mv Localizable.csv l10n/Localizable.csv` and `scripts/l10n` → `l10n/generate`; add the `platforms` column (existing keys = `apple`). Verify: CSV parses with header `key,comment,platforms,en,zh-Hans`
- [ ] 2.2 Extend the generator: skip comment rows, validate `platforms`, report missing translations, filter keys per platform, emit sorted web JSON (`en.json`, `zh-Hans.json`) with dot-nesting and `%@`/`%d`/`%n$@` → `%{n}` conversion, and fail on nesting collisions. Verify: generator unit checks via `ruby l10n/test_generate.rb`
- [ ] 2.3 Point `Rakefile` `l10n` at `l10n/Localizable.csv` with outputs `apple/Shared/Localization` and `web/src/i18n/locales`. Verify: `rake l10n` twice → `git diff --exit-code apple/Shared/Localization` shows no change against the pre-move output, and the second run changes nothing

## 3. Web skeleton from react-tanstarter

- [ ] 3.1 Copy the template into `web/` without `.git`, `node_modules`, `.env*`, `.wrangler`, `dist`, `.tanstack`, or agent files (`.claude`, `.cursor`, `CLAUDE.md`, `AGENTS.md`); rename the package to `murmurs`. Verify: `pnpm --dir web install` succeeds
- [ ] 3.2 Remove demo, account, admin, and auth-UI routes and components; replace the landing page with a Murmurs placeholder; drop `VITE_ALLOW_*` and `ADMIN_EMAILS` from env schemas. Verify: `pnpm --dir web check`
- [ ] 3.3 Make Better Auth dormant (no providers, email/password disabled, no generic OAuth). Verify: covered by test 5.3
- [ ] 3.4 Move web strings into the CSV (`web.*` keys, platforms `web`); switch web locales to `en` / `zh-Hans`, load generated JSON, and set interpolation to `%{…}`. Verify: `rake l10n && pnpm --dir web check`
- [ ] 3.5 Rewrite `wrangler.toml`: dev top level, `[env.staging]`, `[env.production]`, per-env D1 bindings and `ENVIRONMENT`, `migrations_dir = "drizzle"`, no custom domain. Verify: `pnpm --dir web exec wrangler types` succeeds
- [ ] 3.6 Replace `db:push` with `drizzle-kit generate` and `wrangler d1 migrations apply` scripts (local, staging, production); generate the first migration. Verify: `pnpm --dir web db:migrate:local` applies; running it again applies nothing

## 4. /api/v1 foundation

- [ ] 4.1 Add `hono` and `@hono/zod-openapi`; create `src/server/api/` with the app factory, the `ErrorResponse` schema, `defaultHook` (400), `notFound` (404), and `onError` (500). Verify: `pnpm --dir web check`
- [ ] 4.2 Implement `GET /api/v1/health` returning `status`, `version`, `environment`. Verify: covered by test 5.2
- [ ] 4.3 Add `src/routes/api/v1/$.ts` forwarding all methods to the Hono app. Verify: `pnpm --dir web build`

## 5. Tests

- [ ] 5.1 Add `vitest@^4.1` and `@cloudflare/vitest-pool-workers`; `vitest.config.ts` using `wrangler.toml`; `pnpm test` script. Verify: `pnpm --dir web test` runs
- [ ] 5.2 Tests: health 200 body and `environment`, 404 JSON for unknown `/api/v1` path, 400 envelope, 500 envelope without internals. Verify: `pnpm --dir web test` passes
- [ ] 5.3 Test: sign-up and social sign-in requests under `/api/auth/` are rejected and create no user. Verify: `pnpm --dir web test` passes

## 6. Contract

- [ ] 6.1 Add `tsx` and `web/scripts/generate-contract.ts` (OpenAPI 3.0.3) with `pnpm contract:generate`; commit `contract/openapi.json`. Verify: running generation twice leaves `git diff` empty
- [ ] 6.2 Add `contract/scripts/check-drift.sh`. Verify: passes; after a temporary schema edit it fails and prints the regeneration command (edit reverted)
- [ ] 6.3 Add `contract/scripts/check-breaking.sh` (local oasdiff or Docker). Verify: "no baseline" pass on this change; against a copy with a removed response field it fails
- [ ] 6.4 Add `contract/consumers/swift` and `contract/scripts/check-generators.sh [swift|kotlin]`. Verify: `check-generators.sh swift` and `check-generators.sh kotlin` succeed locally

## 7. CI

- [ ] 7.1 Replace `run-unit-tests.yml` with `apple.yml`, and add `web.yml`, `contract.yml`, `l10n.yml` per design D8. Verify: YAML parses (`ruby -ryaml -e 'YAML.load_file(...)'` for each)

## 8. Documentation and configuration

- [ ] 8.1 Update CLAUDE.md (paths, verification commands per area), README.md (layout, requirements, web setup), `openspec/config.yaml` (current layout and commands). Verify: every documented command runs
- [ ] 8.2 Update `docs/architecture.md` for the new layout and the web/API skeleton; tick P0 items in `docs/roadmap.md`. Verify: `openspec validate --all --strict`
- [ ] 8.3 Full verification sweep: Apple build and tests, `rake l10n` idempotent, `pnpm --dir web check && pnpm --dir web test && pnpm --dir web build`, contract drift, breaking, and generator checks, `openspec validate --all --strict`
