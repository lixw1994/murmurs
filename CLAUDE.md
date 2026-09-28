# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Engineering workflow rules (OpenSpec + ADR, Tech Lead / helper roles) live in AGENTS.md and apply to every change:

@AGENTS.md

## Project Overview

**Murmurs** — an iOS/watchOS voice journal app. Users record audio memos, transcribe them (via Apple Speech or OpenAI Whisper), and summarize entries using OpenAI-compatible chat APIs. Includes premium IAP, CSV/Markdown/PDF export, and Apple Watch companion.

## Build & Development

Project uses **XcodeGen** to generate the Xcode project from `project.yml`:

```shell
brew install xcodegen   # one-time setup
xcodegen                # regenerate Murmurs.xcodeproj
```

After generating, open `Murmurs.xcodeproj` in Xcode. The main scheme is `Murmurs` (iOS), with `MurmursWatch` and `SnapshotTests` schemes also defined.

### Running Tests

Unit tests are in the `MurmursTests` target (scheme `Murmurs` → Test). Run from Xcode or:

```shell
xcodebuild test -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Snapshot UI tests use the `SnapshotTests` scheme with the `Snapshot` build configuration.

## Automated Verification

Every code change MUST be verified before considering the step complete. Use the following commands as automated feedback loops.

### Build Verification (required after every code change)

```shell
xcodebuild build -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -5
```

A successful build ends with `** BUILD SUCCEEDED **`. Any other result means the change is broken — fix before proceeding.

### Test Verification (required after logic changes)

```shell
xcodebuild test -project Murmurs.xcodeproj -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -20
```

### Localization Verification (after adding/changing strings)

```shell
rake l10n
```

### Verification Workflow

1. **After every file edit** → run build verification
2. **After logic/model changes** → run build + test verification
3. **After adding localized strings** → run localization + build verification
4. **If verification fails** → read the error, fix, re-verify. Do NOT move to the next step until the current step passes
5. **Autonomous iteration**: each step is a cycle of `edit → verify → fix → re-verify` until green

### Localization

Strings are managed in `Localizable.csv` (key, comment, en, zh-Hans). To regenerate Swift localization files:

```shell
rake l10n
```

This runs `scripts/l10n` which outputs `Shared/Localization/LocalizedKeys.swift`. Use `L(.key)` to reference localized strings in code.

### Deploy to Device

To install a Debug build on a connected iPhone, find the device ID first, then build and install:

```shell
# Find connected device ID
xcodebuild -showdestinations -scheme Murmurs -project Murmurs.xcodeproj 2>&1 | grep "platform:iOS,"

# Build for device (replace DEVICE_ID with actual ID)
xcodebuild build -project Murmurs.xcodeproj -scheme Murmurs -configuration Debug -destination 'id=DEVICE_ID' -derivedDataPath /tmp/murmurs-build 2>&1 | tail -5

# Install to device
xcrun devicectl device install app --device DEVICE_ID /tmp/murmurs-build/Build/Products/Debug-iphoneos/Murmurs.app
```

### Fastlane

Fastlane is configured for App Store deployment. Install with `bundle install`, run with `bundle exec fastlane`.

## Architecture

### Source Layout

- **Sources/** — Main iOS app code
  - `App/` — App entry point, Config (AppStorage-based settings), AppState, MainView (TabView with Timeline + Summary)
  - `Modules/` — Feature modules: Timeline, Recording, Summary, Settings, Export, Premium
  - `Services/` — OpenAI client (chat + whisper), audio player, transcription (Apple Speech), IAP, export
  - `Persistence/` — SwiftData models and DataContainer (MemoEntity, SummaryEntity, PromptEntity, UsageEntity)
  - `Components/`, `Styles/`, `Extensions/`, `Helpers/`, `Models/`
- **Shared/** — Code shared between iOS and watchOS (audio recorder, localization, theme colors, notifications, intents)
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

KeychainAccess, ConfettiSwiftUI, DSWaveformImage, CSV.swift, TPPDF — plus local packages XLog and XLang.

### Deployment Targets

- iOS 17.0, watchOS 10.0
