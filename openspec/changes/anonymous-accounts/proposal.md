## Why

Sync, the server-side pipeline, and quotas (P1–P4) all need to know whose data a request belongs to, so the product needs accounts before P1. The owner chose anonymous accounts with a recovery code over social sign-in for launch. Users start recording immediately with no sign-in screen, and move to a new device with a code they saved. Social sign-in (Apple, Google, email) is deferred. This replaces ADR-0011.

## What Changes

- **Account creation**: the app creates an anonymous account on first launch through `POST /api/v1/accounts`, which returns a session token and a one-time-displayed recovery code.
- **Recovery**: `POST /api/v1/sessions/recover` exchanges a recovery code for a new session on another device. Requests are rate-limited.
- **Account management** (authenticated with a bearer token): `GET /api/v1/me`, rotate the recovery code, sign out the current session, and delete the account. The App Store requires account deletion for apps that create accounts.
- **Server**: Better Auth gains the `anonymous` and `bearer` plugins, and its own sign-in routes stay disabled. Recovery codes are stored only as hashes in a new D1 table. Sessions last one year and are extended on use.
- **iOS**: a local Swift package generated from `contract/openapi.json` provides the API client. An `AccountService` creates or restores the account in the background. It keeps the session token in the device-only Keychain, and keeps the recovery code in the iCloud Keychain, so a new device signed in to the same Apple ID can restore the account automatically. Settings gains an Account section: show and copy the code, rotate it, restore with a code, and delete the account. Debug builds use staging and App Store builds use production.
- **BREAKING (spec)**: the `api-foundation` requirement "Sign-in is disabled" is replaced, because accounts can now be created through `/api/v1`.

## Capabilities

### New Capabilities

- `anonymous-accounts`: server behavior for creating, authenticating, recovering, rotating, signing out of, and deleting anonymous accounts, including recovery code format and storage, session lifetime, and rate limits.
- `ios-account`: iOS app behavior: automatic account creation and restoration, credential storage, and the Settings Account section.

### Modified Capabilities

- `api-foundation`: remove "Sign-in is disabled" (superseded by `anonymous-accounts`). The Better Auth sign-up and sign-in routes and the web UI still offer no sign-in.

## Non-goals

- Social or email sign-in (Apple, Google, OTP), and linking an anonymous account to one. This is deferred; the `anonymous` plugin keeps that path open.
- Web account UI (creating or restoring accounts in the browser). That belongs to P3.
- watchOS changes; the phone keeps uploading for the watch.
- Using the account for any data yet. Sync (P1) is the first consumer.
- Deploying production. Staging only, as before.

## Impact

- **Areas**: server (`web/src/server/api`, `web/src/lib/auth`, D1 migration, rate-limit bindings), contract (new endpoints and error codes), apple (new `Packages/MurmursAPI`, `AccountService`, Settings UI, Info.plist base URL, Keychain), l10n (Account strings), docs. Roadmap phase P0.
- **New dependencies**: Better Auth `anonymous` and `bearer` plugins (already in the installed package); Apple: `swift-openapi-generator`, `swift-openapi-runtime`, `swift-openapi-urlsession`.
- **ADR**: a new ADR supersedes ADR-0011.
- **Contract**: additive only (new endpoints, new error codes); `oasdiff` must pass.
- **Cloudflare**: a new D1 migration and rate-limit bindings on staging.
