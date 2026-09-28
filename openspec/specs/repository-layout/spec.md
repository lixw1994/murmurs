## Purpose

Define the monorepo areas, what each area owns, and the build and verification entry point each area provides, so that a change touching several platforms is verified per area in one repository.

## Requirements

### Requirement: Area directories at the repository root
The repository SHALL organize code into top-level area directories: `apple/` (Swift project for iOS, watchOS, and extensions), `web/` (Cloudflare Worker serving the web UI and the API), `contract/` (API contract), and `l10n/` (localization source and generator), alongside `openspec/`, `adr/`, and `docs/`. The repository root SHALL NOT contain Swift project files or Swift sources.

#### Scenario: Swift project lives under apple/
- **WHEN** a developer lists the repository root
- **THEN** `project.yml`, `Sources/`, `Shared/`, `Watch/`, `WatchWidget/`, `Packages/`, `Resources/`, `Tests/`, `SnapshotTests/`, and `fastlane/` are absent at the root
- **AND** they are present under `apple/`

#### Scenario: Future areas are not pre-created
- **WHEN** this change is complete
- **THEN** no `android/` or `desktop/` directory exists

### Requirement: Apple app is unchanged by the move
Building the Apple project from `apple/` SHALL produce the same targets, schemes, build configurations, bundle identifiers, deployment targets, and app behavior as before the move.

#### Scenario: Build from apple/
- **WHEN** a developer runs `xcodegen` and then `xcodebuild build` for the `Murmurs` scheme inside `apple/`
- **THEN** the build succeeds

#### Scenario: Tests from apple/
- **WHEN** a developer runs `xcodebuild test` for the `Murmurs` scheme inside `apple/`
- **THEN** the unit tests pass

#### Scenario: Watch app builds
- **WHEN** a developer builds the `MurmursWatch` scheme inside `apple/`
- **THEN** the build succeeds

#### Scenario: Release tooling works from apple/
- **WHEN** a developer runs `bundle exec fastlane tests` inside `apple/`
- **THEN** fastlane finds the project and runs the unit tests

### Requirement: Each area provides a verification entry point
Each area SHALL provide documented commands to verify it: `apple/` build and test; `web/` format, lint, and type check, tests, and production build; `contract/` up-to-date and breaking-change checks; `l10n/` generation. These commands SHALL be listed in CLAUDE.md and in `openspec/config.yaml`, and SHALL succeed on a clean checkout of the main branch.

#### Scenario: Documented commands succeed
- **WHEN** a developer runs each documented verification command on a clean checkout of the main branch
- **THEN** every command exits successfully

### Requirement: CI verifies the areas a change affects
CI SHALL run on pull requests and on pushes to the main branch, and SHALL run the verification for each area whose files changed. A change to `contract/` or to the API in `web/` SHALL also run the contract checks.

#### Scenario: Web-only change
- **WHEN** a pull request changes files only under `web/`
- **THEN** CI runs the `web/` and `contract/` verification
- **AND** CI does not build the Apple project

#### Scenario: Apple-only change
- **WHEN** a pull request changes files only under `apple/`
- **THEN** CI builds and tests the Apple project

#### Scenario: Localization change
- **WHEN** a pull request changes `l10n/Localizable.csv`
- **THEN** CI verifies that the generated Apple and web localization files are up to date
