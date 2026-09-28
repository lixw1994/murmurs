# ADR-0008: Require iOS 18 and watchOS 11

- Status: accepted
- Date: 2026-09-28
- Supersedes: —
- Deciders: project owner, Tech Lead

## Context and Problem Statement

The app targeted iOS 17 and watchOS 10. It has not launched, so there is no installed base to preserve. iOS 18 adds SwiftUI APIs that close gaps relevant to this app, including `ScrollPosition` and `onScrollGeometryChange` for Timeline date navigation, custom containers, and zoom transitions (ADR-0007).

## Considered Options

- iOS 18.0 / watchOS 11.0
- Keep iOS 17.0 / watchOS 10.0

## Decision Outcome

Chosen option: "iOS 18.0 / watchOS 11.0", because there are no existing users to strand and the newer SwiftUI APIs reduce the need for UIKit workarounds.

### Consequences

- Good, because the app has fewer availability branches and uses more capable SwiftUI.
- Bad, because devices that cannot run iOS 18 or watchOS 11 are excluded. The exact share is Unknown and should be checked before launch.
- Done: all targets in `project.yml` now use 18.0 / 11.0. Local SPM packages keep lower minimums, which is compatible.
