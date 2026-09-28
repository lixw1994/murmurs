## ADDED Requirements

### Requirement: Create an anonymous account
`POST /api/v1/accounts` SHALL create an anonymous account without any credentials and return HTTP 201 with the account's `userId`, a session `token`, and a `recoveryCode`. The recovery code SHALL be returned only by this endpoint and by recovery code rotation; no other endpoint SHALL return it.

#### Scenario: New account
- **WHEN** a client sends `POST /api/v1/accounts`
- **THEN** the response status is 201 with `userId`, `token`, and `recoveryCode`
- **AND** `GET /api/v1/me` with that token reports the same `userId` and `isAnonymous` equal to `true`

#### Scenario: Recovery code is not readable later
- **WHEN** a client calls `GET /api/v1/me`
- **THEN** the response does not contain the recovery code

### Requirement: Recovery code format and storage
A recovery code SHALL consist of 25 characters from the Crockford base32 alphabet, generated from a cryptographically secure random source, and displayed as five hyphen-separated groups of five characters. The server SHALL accept codes case-insensitively, ignoring spaces and hyphens and mapping `O` to `0` and `I`/`L` to `1`. The server SHALL store only a SHA-256 hash of the normalized code and SHALL NOT store or log the plaintext.

#### Scenario: Code format
- **WHEN** an account is created
- **THEN** `recoveryCode` matches `^[0-9A-HJKMNP-TV-Z]{5}(-[0-9A-HJKMNP-TV-Z]{5}){4}$`

#### Scenario: Lenient input
- **WHEN** a client recovers with the code in lowercase and without hyphens
- **THEN** recovery succeeds

#### Scenario: No plaintext at rest
- **WHEN** the recovery code table is inspected after an account is created
- **THEN** it contains a hash that differs from the code, and the code itself does not appear

### Requirement: Bearer authentication and session lifetime
Authenticated `/api/v1` endpoints SHALL accept `Authorization: Bearer <token>`. A missing, unknown, expired, or revoked token SHALL produce HTTP 401 with error code `unauthorized`. Sessions SHALL expire 365 days after their last extension, and the server SHALL extend a session when it is used more than one day after its last extension.

#### Scenario: Missing token
- **WHEN** a client calls `GET /api/v1/me` without an `Authorization` header
- **THEN** the response status is 401 with `error.code` equal to `"unauthorized"`

#### Scenario: Unknown token
- **WHEN** a client calls `GET /api/v1/me` with a token the server did not issue
- **THEN** the response status is 401 with `error.code` equal to `"unauthorized"`

#### Scenario: Long-lived session
- **WHEN** an account is created
- **THEN** its session expires no earlier than 364 days later

### Requirement: Recover an account on another device
`POST /api/v1/sessions/recover` with a `recoveryCode` SHALL create a new session for the account that owns the code and return HTTP 200 with `userId` and `token`. Existing sessions of that account SHALL remain valid. An unknown or malformed code SHALL produce HTTP 401 with error code `invalid_recovery_code`, and the response SHALL NOT reveal whether the code was malformed or unknown.

#### Scenario: Successful recovery
- **WHEN** a client recovers with a valid recovery code
- **THEN** the response contains the account's `userId` and a new token
- **AND** both the new token and the account's earlier tokens authenticate

#### Scenario: Wrong code
- **WHEN** a client recovers with a well-formed code that belongs to no account
- **THEN** the response status is 401 with `error.code` equal to `"invalid_recovery_code"`

### Requirement: Rate limits on unauthenticated account endpoints
The server SHALL apply per-client-IP rate limits of 5 requests per minute to account recovery and 10 requests per minute to account creation, and SHALL answer requests that the limiter rejects with HTTP 429 and error code `rate_limited`. Enforcement MAY be approximate: Cloudflare's rate limiter counts per location and is eventually consistent, so some requests beyond the nominal limit can pass. The limits are abuse protection; the recovery code's entropy, not the limiter, protects accounts from guessing.

#### Scenario: Too many recovery attempts
- **WHEN** a client keeps sending recovery requests well beyond the limit within a minute
- **THEN** requests start receiving status 429 with `error.code` equal to `"rate_limited"`

#### Scenario: Exact limit where the limiter is exact
- **WHEN** a client exceeds the limit against the local runtime (Miniflare), where counting is exact
- **THEN** the requests beyond the limit receive status 429

### Requirement: Account information
`GET /api/v1/me` SHALL return the authenticated account's `userId`, `isAnonymous`, `createdAt`, and `recoveryCodeCreatedAt`.

#### Scenario: Read account information
- **WHEN** an authenticated client calls `GET /api/v1/me`
- **THEN** the response status is 200 with those four fields

### Requirement: Rotate the recovery code
`POST /api/v1/me/recovery-code` SHALL replace the authenticated account's recovery code, return the new code, and make the previous code invalid. Existing sessions SHALL remain valid.

#### Scenario: Old code stops working
- **WHEN** a client rotates the recovery code and then recovers with the previous code
- **THEN** recovery fails with `invalid_recovery_code`
- **AND** recovery with the new code succeeds

### Requirement: Sign out the current session
`DELETE /api/v1/sessions/current` SHALL revoke the session whose token authenticated the request and return HTTP 204. Other sessions of the account SHALL remain valid.

#### Scenario: Token no longer works
- **WHEN** a client signs out and then calls `GET /api/v1/me` with the same token
- **THEN** the response status is 401

### Requirement: Delete the account
`DELETE /api/v1/me` SHALL permanently delete the authenticated account, all of its sessions, and its recovery code, and return HTTP 204.

#### Scenario: Deleted account is unusable
- **WHEN** a client deletes its account
- **THEN** every token of that account returns 401
- **AND** recovering with the account's recovery code fails with `invalid_recovery_code`

### Requirement: Accounts only through /api/v1
Accounts SHALL be created and restored only through `/api/v1` endpoints. The Better Auth routes under `/api/auth/` SHALL NOT allow sign-up or sign-in by email, social provider, or anonymous sign-in, and the web UI SHALL NOT show sign-in or sign-up pages.

#### Scenario: Better Auth sign-in routes are closed
- **WHEN** a client sends a request to the email sign-up, email sign-in, social sign-in, or anonymous sign-in route under `/api/auth/`
- **THEN** the request is rejected and no user or session is created

#### Scenario: No sign-in UI
- **WHEN** a visitor opens the web UI
- **THEN** no sign-in or sign-up page or link is available
