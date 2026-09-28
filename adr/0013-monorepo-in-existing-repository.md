# ADR-0013: Restructure the existing repository into a monorepo

- Status: accepted
- Date: 2026-09-28
- Supersedes: —
- Deciders: project owner, Tech Lead

## Context and Problem Statement

Apple, Android, web/server, the API contract, localization, and cross-platform specs change together for most features. AI agents work best when all affected code is visible in one workspace. The current repository holds the iOS/watchOS app, its OpenSpec history, and its git history.

## Considered Options

- Convert the current repository into a monorepo: `apple/`, `android/`, `web/`, `desktop/`, `contract/`, `l10n/`, `openspec/`, `docs/`, `adr/`
- A new repository per platform
- A new monorepo, leaving this repository archived

## Decision Outcome

Chosen option: "Convert the current repository", because it keeps git and OpenSpec history, lets a single change update the contract, the server, and every client atomically, and gives agents full cross-platform context.

### Consequences

- Good, because there is one PR per feature across platforms, and there are shared specs, ADRs, and localization.
- Bad, because the Swift project moves under `apple/`, so build commands, CI, and fastlane paths must be updated.
- Bad, because the repository mixes toolchains (Xcode, Gradle, pnpm), so CI must build only the affected areas.
- Follow-up: `Localizable.csv` moves to `l10n/` and generates Swift strings, Android `strings.xml`, and i18next JSON.
