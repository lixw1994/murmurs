# ADR-0001: Build a native client per platform

- Status: accepted
- Date: 2026-09-28
- Supersedes: —
- Deciders: project owner, Tech Lead

## Context and Problem Statement

Murmurs ships only as a native iOS/watchOS app. The product must also reach Android, the web, and desktop. The fastest capture paths — Apple Watch, Live Activity / Dynamic Island, Action Button, Siri, widgets — are the product's core value and are Apple-native APIs. AI-assisted development has sharply reduced the cost of writing and porting code, while build, device QA, and release effort still scale with the number of platforms.

## Considered Options

- Native per platform: SwiftUI (Apple), Kotlin + Jetpack Compose (Android), React (web, wrapped by Electron for desktop)
- Expo / React Native for iOS + Android (+ web via react-native-web), native extensions via `expo-apple-targets`
- Electron + web only, keeping iOS native

## Decision Outcome

Chosen option: "Native per platform", because the existing SwiftUI app and its Watch/Widget/Live Activity code are kept rather than rewritten, capture-centric Apple features stay first-class instead of bridged, and SwiftUI maps closely to Compose, which makes AI-driven Android porting practical. The duplication cost is contained by moving logic server-side (ADR-0002) and by generated contracts (ADR-0010).

### Consequences

- Good, because the iOS/watchOS codebase and its native integrations are reused.
- Good, because each platform gets idiomatic UX and full OS API access.
- Bad, because every user-facing feature needs up to three client implementations, builds, and QA passes.
- Bad, because client behaviour can drift across platforms.
- Follow-up: cross-platform OpenSpec specs per feature, shared sync conformance fixtures, and a single localization source (ADR-0013).
