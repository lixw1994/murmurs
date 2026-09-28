# ADR-0012: Sell subscriptions through RevenueCat across all platforms

- Status: accepted
- Date: 2026-09-28
- Supersedes: —
- Deciders: project owner, Tech Lead

## Context and Problem Statement

The current app sells a one-time premium unlock through StoreKit 1. Server-side transcription, AI, and storage (ADR-0002) create recurring per-user costs. Entitlements must be consistent across App Store, Google Play, and web purchases, and quotas are enforced by the server.

## Considered Options

- Subscriptions managed by RevenueCat (App Store, Play Billing, Web Billing via Stripe); a webhook writes entitlements to D1; the API enforces quotas
- Keep the one-time purchase
- Integrate StoreKit 2, Play Billing, and Stripe directly

## Decision Outcome

Chosen option: "Subscriptions via RevenueCat", because recurring costs need recurring revenue, and RevenueCat unifies cross-platform entitlements behind one webhook instead of three receipt-validation integrations.

### Consequences

- Good, because a purchase on any platform unlocks every platform.
- Good, because the StoreKit 1 `IAPManager` is removed.
- Bad, because it adds a paid third-party dependency and revenue share on top of store fees.
- Unknown: free and paid quota numbers and prices. They will be decided in P4 using `usage_daily` cost data.
