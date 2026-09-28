# ADR Review Manifest

## ADR Review Completed

- Date: 2026-09-28
- Reviewer: Tech Lead
- Change: anonymous-accounts

## In-Force ADR Context Reviewed

- adr/0002-thick-server-thin-clients.md - account logic lives on the server; the iOS client only stores credentials
- adr/0003-cloudflare-as-backend-platform.md - D1 for accounts, Workers rate-limiting bindings
- adr/0004-single-worker-from-react-tanstarter.md - native clients use only /api/v1, so account endpoints live there, not under /api/auth
- adr/0005-per-user-durable-object-with-custom-sync.md - the account userId becomes the key of the per-user Durable Object in P1
- adr/0007-swiftui-first-with-uikit-bridging.md - Account settings UI in SwiftUI
- adr/0010-openapi-contract-with-generated-clients.md - the iOS client is generated from the committed contract
- adr/0011-authentication-apple-google-email-otp.md - superseded by this change
- adr/0012-subscriptions-via-revenuecat.md - quotas will bound anonymous account abuse later
- adr/0014-api-v1-compatibility-policy.md - new endpoints and error codes are additive
- adr/0001, 0006, 0008, 0009, 0013 - reviewed; not affected

## Repository-Level ADRs Created

- adr/0015-anonymous-accounts-with-recovery-codes.md - anonymous accounts with recovery codes (iCloud Keychain on iOS) replace social sign-in for launch; supersedes ADR-0011

## Notes

- Recovery code format, storage, rate limits, session lifetime, and the iOS package layout are recorded in design.md.
