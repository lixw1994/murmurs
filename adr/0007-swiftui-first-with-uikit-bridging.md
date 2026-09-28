# ADR-0007: Use SwiftUI by default on Apple platforms and bridge to UIKit where needed

- Status: accepted
- Date: 2026-09-28
- Supersedes: —
- Deciders: project owner, Tech Lead

## Context and Problem Statement

UIKit is more mature and gives finer control, especially for complex lists and text editing. The existing app is SwiftUI-first (57 SwiftUI files and 4 UIKit imports), and it already bridges `UITextView` (`MyTextView`) and the share sheet. watchOS apps, WidgetKit, Live Activities, and App Intents snippets are SwiftUI-only.

## Considered Options

- SwiftUI by default, with UIKit bridged per screen when a concrete problem appears on device
- UIKit for the main iOS app, with SwiftUI only where required

## Decision Outcome

Chosen option: "SwiftUI by default", because several required surfaces can only use SwiftUI, the existing code is already SwiftUI, SwiftUI concepts map closely to Jetpack Compose for Android porting (ADR-0001), and SwiftUI code is more compact for AI-assisted development and review.

### Consequences

- Good, because there is one UI paradigm across iOS, watchOS, and extensions.
- Good, because it ports more easily to Compose.
- Bad, because SwiftUI gaps (text editing, very long lists, focus and keyboard edge cases) need targeted UIKit bridges.
- Rule: replace a screen with UIKit only after a problem is observed on a real device.
