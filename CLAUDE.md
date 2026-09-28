# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Engineering workflow rules (OpenSpec + ADR, Tech Lead / helper roles) live in AGENTS.md and apply to every change:

@AGENTS.md

## Project Overview

**Murmurs** — a voice journal. Users record audio memos, transcribe them (Apple Speech or OpenAI Whisper), and summarize entries with OpenAI-compatible chat APIs. The shipped product is the iOS/watchOS app, which keeps all data on device and includes premium IAP, CSV/Markdown/PDF export, Readwise sync, and an Apple Watch companion.

The project is pre-launch and is being rebuilt into a multi-platform product: native Apple/Android clients, a web app with an Electron desktop shell, and one Cloudflare Worker backend with per-user Durable Object sync. The monorepo layout and the Worker skeleton (`/api/v1`, no sign-in yet) exist; sync and product features come in later phases.

- `adr/` — in-force architecture decisions (ADR-0001..); read before designing any change
- `docs/architecture.md` — current system; `docs/roadmap.md` — phases P0–P6
- `openspec/` — capability specs and changes; `openspec/config.yaml` holds project context and artifact rules

## Repository Layout

| Directory | Owns |
|---|---|
| `apple/` | Swift project (XcodeGen `project.yml`): iOS app, watchOS app, widgets, tests, fastlane |
| `web/` | One Cloudflare Worker (from `react-tanstarter`): TanStack Start web UI, Hono API at `/api/v1`, Better Auth (no providers enabled), D1 |
| `contract/` | `openapi.json` generated from the API, and the drift, breaking-change, and generator checks |
| `l10n/` | `Localizable.csv` (single string source for Apple and web) and its generator |
| `openspec/`, `adr/`, `docs/` | specs and changes, architecture decisions, documentation |

## Automated Verification

Every code change MUST be verified before considering the step complete. Run the commands for each area you touched.

| Area | Command | Passes when |
|---|---|---|
| Apple build (every Apple edit) | `cd apple && xcodebuild build -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 \| tail -5` | ends with `** BUILD SUCCEEDED **` |
| Apple tests (logic changes) | `cd apple && xcodebuild test -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 \| tail -20` | `** TEST SUCCEEDED **` |
| Web | `pnpm --dir web check && pnpm --dir web test && pnpm --dir web build` | all exit 0 |
| Contract (API changes) | `pnpm --dir web contract:generate`, then `contract/scripts/check-drift.sh` and `contract/scripts/check-breaking.sh` | "up to date" and no breaking changes |
| Contract consumers (API changes) | `contract/scripts/check-generators.sh` (Swift; Docker for Kotlin) | "Contract is consumable" |
| Localization (string changes) | `rake l10n` and `ruby l10n/test_generate.rb` | generation succeeds; tests pass |
| Specs | `openspec validate --all --strict` | all pass (also run by the pre-commit hook) |

Run `xcodegen` inside `apple/` first if `project.yml` or the file layout changed.

### Verification Workflow

1. **After every file edit** → run the build or check for that area
2. **After logic/model changes** → also run that area's tests
3. **After adding localized strings** → run localization, then the Apple build and web check
4. **After API changes** → regenerate the contract and run the contract checks
5. **If verification fails** → read the error, fix, re-verify. Do NOT move to the next step until the current step passes
6. **Autonomous iteration**: each step is a cycle of `edit → verify → fix → re-verify` until green

## Apple Development (`apple/`)

```shell
brew install xcodegen   # one-time setup
cd apple
xcodegen                # regenerate Murmurs.xcodeproj
```

Open `apple/Murmurs.xcodeproj` in Xcode. The main scheme is `Murmurs` (iOS), with `MurmursWatch` and `SnapshotTests` schemes also defined. Unit tests are in the `MurmursTests` target; snapshot UI tests use the `SnapshotTests` scheme with the `Snapshot` build configuration.

### Deploy to Device

Find the device ID, then build and install from `apple/`:

```shell
cd apple
xcodebuild -showdestinations -scheme Murmurs -project Murmurs.xcodeproj 2>&1 | grep "platform:iOS,"
xcodebuild build -project Murmurs.xcodeproj -scheme Murmurs -configuration Debug -destination 'id=DEVICE_ID' -derivedDataPath /tmp/murmurs-build 2>&1 | tail -5
xcrun devicectl device install app --device DEVICE_ID /tmp/murmurs-build/Build/Products/Debug-iphoneos/Murmurs.app
```

### Fastlane

Fastlane lives in `apple/fastlane`. From `apple/`: `bundle install`, then `bundle exec fastlane tests` or `bundle exec fastlane beta`.

## Web Development (`web/`)

```shell
pnpm --dir web install
pnpm --dir web db:migrate:local   # apply D1 migrations to the local database
pnpm --dir web dev                # http://localhost:3000, API at /api/v1
```

- Local secrets go in `web/.dev.vars` (copy `web/.dev.vars.example`). Only `/api/auth/*` needs `BETTER_AUTH_SECRET`.
- D1 schema: edit `web/src/lib/db/schema/`, run `pnpm --dir web db:generate`, commit the migration in `web/drizzle/`.
- API: add routes under `web/src/server/api/routes/` with `createRoute` schemas and the shared error responses; native clients use only `/api/v1` (ADR-0004), and `/api/v1` stays backward compatible (ADR-0014).
- Environments: top-level `wrangler.toml` is local development; `[env.staging]` and `[env.production]` deploy with `pnpm --dir web deploy:staging` / `deploy:production` after their D1 ids and secrets are set.

## Localization (`l10n/`)

`l10n/Localizable.csv` has the columns `key, comment, platforms, en, zh-Hans`. `platforms` is `apple`, `web`, or `apple web`; web-only keys use the `web.` namespace. `rake l10n` generates:

- `apple/Shared/Localization/LocalizedKeys.swift` and `<lang>.lproj/*.strings` — use `L(.key)` in Swift
- `web/src/i18n/locales/<lang>.json` — use `t("key")`; `%@`/`%d` become `%{0}`, `%{1}` for i18next

Never edit generated files by hand.

## Apple Architecture

### Source Layout (under `apple/`)

- **Sources/** — Main iOS app code
  - `App/` — App entry point, Config (AppStorage-based settings), AppState, MainView (TabView with Timeline + Summary)
  - `Modules/` — Feature modules: Timeline, Recording, Summary, Settings, Export, Premium
  - `Services/` — OpenAI client (chat + whisper), audio player, transcription (Apple Speech, live SpeechAnalyzer/SFSpeechRecognizer), IAP (StoreKit 1), Readwise, export
  - `Persistence/` — SwiftData models and DataContainer (MemoEntity, SummaryEntity, PromptEntity, UsageEntity)
  - `Components/`, `Styles/`, `Extensions/`, `Helpers/`, `Models/`
- **Shared/** — Code shared between iOS and watchOS (audio recorder, localization, theme colors, notifications, intents, Live Activity)
- **Watch/** — watchOS app
- **WatchWidget/** — WidgetKit extensions (iOS + watchOS)
- **Packages/** — Local SPM packages: `XLog` (logging), `XLang` (language/localization utilities)
- **Tests/** — Unit tests with mocks under `Tests/Mocks/`

### Key Patterns

- **MVVM**: ViewModels are `@Observable` classes (e.g., `TimelineViewModel`, `AddSummaryViewModel`, `QuickMemoViewModel`)
- **SwiftData**: Persistence layer using `ModelContainer`/`ModelContext` via `DataContainer.shared`
- **Protocol-based testability**: Services use protocols (`AIClientProtocol`, `ConfigProtocol`, `MemoStoreProtocol`, `TranscriptionServiceProtocol`) with mock implementations in tests
- **Singleton services**: `Config.shared`, `DataContainer.shared`, `OpenAIClient.shared`, `AppState.shared`
- **API keys**: Stored in Keychain via `KeychainAccess`, not in UserDefaults

### Build Configurations

- `Debug` — development
- `Snapshot` — adds `SNAPSHOT` compilation condition for UI snapshot tests
- `AppStore` — release

### Dependencies (SPM)

KeychainAccess, ConfettiSwiftUI, DSWaveformImage, CSV.swift, TPPDF, MarkdownUI — plus local packages XLog and XLang.

### Deployment Targets

- iOS 18.0, watchOS 11.0
