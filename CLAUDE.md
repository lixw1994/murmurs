# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
xcodebuild test -scheme Murmurs -destination 'platform=iOS Simulator,name=iPhone 16'
```

Snapshot UI tests use the `SnapshotTests` scheme with the `Snapshot` build configuration.

### Localization

Strings are managed in `Localizable.csv` (key, comment, en, zh-Hans). To regenerate Swift localization files:

```shell
rake l10n
```

This runs `scripts/l10n` which outputs `Shared/Localization/LocalizedKeys.swift`. Use `L(.key)` to reference localized strings in code.

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
