## Context

`/api/v1` exists with only `GET /health`. Better Auth 1.4.22 is mounted at `/api/auth/*` with no providers, and its tables are in D1 (`web/src/lib/db/schema/auth.schema.ts`). The iOS app keeps all data locally and has no API client. The contract (`contract/openapi.json`) is consumed by the SwiftPM check package in `contract/consumers/swift`. Staging runs at `https://murmurs-staging.denkit.app`.

Verified in the installed packages (2026-09-28):

| Item | Fact |
|---|---|
| Better Auth `anonymous` plugin | adds `user.isAnonymous`; its `/sign-in/anonymous` endpoint calls `internalAdapter.createUser({ email, isAnonymous: true, … })` then `internalAdapter.createSession(userId)` and returns `session.token`; `emailDomainName` controls the placeholder email |
| Better Auth `bearer` plugin | a before-hook turns `Authorization: Bearer <token>` into the session cookie; unsigned raw session tokens are accepted unless `requireSignature` is set; applies to `auth.api.getSession({ headers })` |
| `internalAdapter.createSession(userId)` | generates a 32-character token; expiry from `session.expiresIn`; works outside an endpoint context |
| `disabledPaths` | Better Auth answers 404 for listed paths before any handler runs |
| Session defaults | `expiresIn` 7 days, `updateAge` 1 day |
| wrangler 4.98 | supports `[[ratelimits]]` bindings (`name`, `namespace_id`, `simple = { limit, period }`); Miniflare simulates them locally |
| iOS app | protocol-based services with mocks in `Tests/Mocks`, XCTest; `KeychainAccess` is already a dependency; unit tests run inside the app host |

## Goals / Non-Goals

**Goals:**
- Server: create, authenticate, recover, rotate, sign out, delete anonymous accounts under `/api/v1`, with the contract updated additively.
- iOS: an account exists after the first online launch without any UI; the recovery code survives a device change through iCloud Keychain; Settings lets the user manage it.

**Non-Goals:**
- Social sign-in and account linking; web account UI; watchOS; production deploy (see proposal).

## Decisions

### D1. Better Auth stays the user and session store; native endpoints live in /api/v1

Enable the `anonymous` (with `emailDomainName: "anonymous.murmurs.denkit.app"`) and `bearer` plugins. Set `session.expiresIn` to 365 days and keep `updateAge` at 1 day, so sessions extend on use. Disable Better Auth's own entry points with `disabledPaths: ["/sign-in/anonymous", "/sign-up/email", "/sign-in/email", "/sign-in/social"]`. This way `/api/v1` is the only way to create or restore accounts, and it applies rate limits and issues recovery codes.

`/api/v1` handlers obtain `auth.$context.internalAdapter` to create users and sessions, and use `auth.api.getSession({ headers })` (bearer plugin) to authenticate. Social sign-in can later reuse the same user table, and the `anonymous` plugin already supports linking an anonymous user to a real account.

`getAuth(db, env)` now takes its secret and base URL from the Worker `env` instead of `process.env`, so the API and the tests pass bindings explicitly. `server-entry.ts` passes `env`. The `tanstackStartCookies` plugin is removed: its after-hook imports TanStack Start server internals, which breaks `auth.api.getSession` when it is called from the Hono API (and from tests). Nothing calls `auth.api` from TanStack Start server functions, and `/api/auth/*` returns cookies through `auth.handler` directly.

*Alternative:* a custom users and sessions implementation without Better Auth. Rejected: it would have to be replaced or bridged when social sign-in returns, and Better Auth already provides session storage, expiry, and extension.

### D2. Recovery codes

- **Format**: 16 random bytes from `crypto.getRandomValues`; the first 125 bits become 25 Crockford base32 characters, shown as `XXXXX-XXXXX-XXXXX-XXXXX-XXXXX`.
- **Normalization**: uppercase; remove spaces and hyphens; map `O`→`0`, `I`/`L`→`1`. Anything that is not 25 base32 characters afterwards is treated as an unknown code.
- **Storage**: new D1 table `recovery_code (user_id TEXT PRIMARY KEY REFERENCES user(id) ON DELETE CASCADE, code_hash TEXT NOT NULL UNIQUE, created_at INTEGER NOT NULL)`. `code_hash` is the lowercase hex SHA-256 of the normalized code. With 125 bits of entropy, a fast hash is sufficient, and the unique index gives O(1) lookup.
- **Rotation** updates the row in place. Deleting the user cascades; the handler also deletes explicitly.

### D3. Endpoints

| Method and path | Auth | Success | Errors |
|---|---|---|---|
| `POST /api/v1/accounts` | none, rate-limited | 201 `{ userId, token, recoveryCode }` | 429 `rate_limited` |
| `POST /api/v1/sessions/recover` `{ recoveryCode }` | none, rate-limited | 200 `{ userId, token }` | 401 `invalid_recovery_code`, 429 `rate_limited` |
| `GET /api/v1/me` | bearer | 200 `{ userId, isAnonymous, createdAt, recoveryCodeCreatedAt }` | 401 `unauthorized` |
| `POST /api/v1/me/recovery-code` | bearer | 200 `{ recoveryCode }` | 401 |
| `DELETE /api/v1/sessions/current` | bearer | 204 | 401 |
| `DELETE /api/v1/me` | bearer | 204 | 401 |

A `requireSession` Hono middleware resolves the session and stores `{ user, session }` in the context. Timestamps are ISO-8601 strings. A `bearerAuth` security scheme is registered in the contract and referenced by authenticated operations. The new error codes (`unauthorized`, `invalid_recovery_code`, `rate_limited`) are added to `ERROR_CODES`. `error.code` stays a string in the contract, so the change is additive.

### D4. Rate limits with Workers rate-limiting bindings

Add `[[ratelimits]]` bindings `ACCOUNT_CREATE_LIMITER` (10 per 60 s) and `ACCOUNT_RECOVER_LIMITER` (5 per 60 s), keyed by `cf-connecting-ip` (falling back to a constant key when absent, which is the local and test case). Bindings are not inherited by environments, so they are declared at the top level and in `[env.staging]` and `[env.production]`, each with its own `namespace_id`.

### D5. iOS API client: local package `apple/Packages/MurmursAPI`

Move the SwiftPM consumer from `contract/consumers/swift` to `apple/Packages/MurmursAPI`. Its `Sources/MurmursAPI/openapi.json` is a symlink to `contract/openapi.json`; it uses the `swift-openapi-generator` build plugin and depends on `swift-openapi-runtime` and `swift-openapi-urlsession`. The app and the contract check now build the same package, and `check-generators.sh swift` points to it.

Xcode build tool plugins must be trusted. Command-line builds (CLAUDE.md, `openspec/config.yaml`, the Fastlane `tests` lane, and CI) add `-skipPackagePluginValidation`; in the Xcode GUI, the developer approves the plugin once.

### D6. iOS account logic

- `CredentialStore` protocol, backed by `KeychainCredentialStore` (KeychainAccess, service `com.tangyue.murmurs.account`). The token uses `synchronizable(false)` with `afterFirstUnlockThisDeviceOnly`; the recovery code uses `synchronizable(true)` with `afterFirstUnlock`.
- `AccountAPI` protocol wraps the generated `Client` and maps responses to `AccountAPIError` (`.unauthorized`, `.invalidRecoveryCode`, `.rateLimited`, `.network`, `.server`). Authenticated methods take the token as a parameter. `MurmursAPI` provides `BearerTokenMiddleware` and `Client.murmurs(serverURL:token:)`; the package depends on `swift-http-types` explicitly, because the app target cannot import `HTTPTypes` transitively.
- **Follow-up**: only recovery-code rotation and account deletion call the API with a token today, and both go through `AccountService`'s `authorized` helper, which recovers once on `unauthorized`. The P1 sync engine must use the same helper.
- `AccountService` (`@Observable`, `@MainActor`) exposes `state` (`.none`, `.working`, `.ready(userId)`, `.needsRestore`) and `ensureAccount()`, `recoveryCode`, `rotateRecoveryCode()`, `restore(code:)`, `deleteAccount()`, and `refreshAfterUnauthorized()`. `ensureAccount()` is idempotent. It returns if a token exists, recovers if only a code exists, and otherwise creates an account. Network failures leave the state `.none` for a later retry.
- **Trigger**: `MurmursApp` calls `ensureAccount()` when the scene becomes active. The call is skipped under `#if SNAPSHOT` and when `XCTestConfigurationFilePath` is set.
- **Base URL**: Info.plist key `MurmursAPIBaseURL = $(MURMURS_API_BASE_URL)`, a build setting per configuration: Debug and Snapshot use staging, AppStore uses production.
- **UI**: `AccountSettingsView` and `AccountViewModel`, reached from a new Account section at the top of Settings. Strings come from `l10n/` (`platforms` `apple`).

*Alternative:* commit generated Swift sources instead of using the build plugin. Rejected: it needs its own drift check, while the plugin regenerates from the committed contract on every build.

## Risks / Trade-offs

- [A lost recovery code without iCloud Keychain means the account cannot be recovered] → The Account section explains this and offers copy. Social sign-in, added later, adds a second recovery path.
- [iCloud Keychain synchronization cannot be exercised in the simulator] → Unit tests cover the "code present, token absent" path. Real-device verification is listed as a manual follow-up.
- [Anyone can create accounts] → Per-IP rate limit. Accounts cost one D1 row until sync stores data; quotas arrive with billing (P4).
- [Build tool plugin trust prompts] → Documented, and `-skipPackagePluginValidation` is used for command-line and CI builds.
- [`cf-connecting-ip` is absent locally, so every local request shares one bucket] → Acceptable for development; tests rely on it to exercise the limit.
- [Cloudflare's rate limiter is approximate (per-location, eventually consistent). On staging, 24 of 40 rapid recovery requests passed before the first 429 appeared.] → Accepted: 125-bit codes make guessing infeasible regardless of rate, so the limit only curbs abuse. If exact limits become necessary, add a per-IP Durable Object counter. The spec states that enforcement is approximate.

## Migration Plan

1. `pnpm --dir web db:generate --name anonymous_accounts` creates migration 0001 (`user.is_anonymous` and the `recovery_code` table); apply locally, then to staging (`db:migrate:staging`).
2. Deploy staging (`pnpm --dir web deploy:staging`). Verify account creation, `/me`, recovery, rotation, sign-out, deletion, and the rate limit against `https://murmurs-staging.denkit.app`.
3. Rollback: `wrangler rollback --env staging`. The migration only adds a column and a table.

## Open Questions

- None blocking. The `emailDomainName` placeholder emails are never shown or used for delivery.
