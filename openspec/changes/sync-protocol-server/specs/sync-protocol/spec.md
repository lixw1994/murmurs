## ADDED Requirements

### Requirement: Synced record types
The server SHALL sync four record types for each account: `memos`, `summaries`, and `prompts` (identified by client-generated UUIDs) and `settings` (identified by a key of 1–64 characters from `[a-z0-9_.-]`). Every record SHALL carry `updatedAt` (milliseconds since the Unix epoch), `deletedAt` (milliseconds or null), and type-specific `fields`, and SHALL be validated against its type's schema:

- `memos`: `content` (string, ≤ 200,000 chars), `polished` (string or null, ≤ 200,000), `title` (string or null, ≤ 500), `createdAt` (ms), `timezone` (string, ≤ 64), `day` (integer), `isHidden` (boolean), `duration` (number ≥ 0), `source` (`ios`, `watch`, `android`, `web`, or `desktop`)
- `summaries`: `title` (string, ≤ 500), `content` (string, ≤ 200,000), `memoIds` (≤ 1,000 UUIDs), `prompt` (string or null, ≤ 20,000), `model` (string or null, ≤ 200), `temperature` (number, 0–2), `createdAt` (ms), `timezone` (string, ≤ 64)
- `prompts`: `title` (string, ≤ 200), `content` (string, ≤ 20,000), `description` (string or null, ≤ 1,000), `temperature` (number, 0–2), `createdAt` (ms)
- `settings`: `value` (any JSON value, ≤ 10,000 characters when serialized)

Unknown fields SHALL be ignored. A push containing an invalid change SHALL be rejected as a whole with HTTP 400 `invalid_request`, identifying the invalid change, and SHALL apply nothing.

#### Scenario: Valid memo
- **WHEN** a client pushes a memo with a UUID id and valid fields
- **THEN** the change is applied

#### Scenario: Invalid change rejects the batch
- **WHEN** a push contains one valid memo and one memo whose `source` is `"fax"`
- **THEN** the response status is 400 with `error.code` equal to `"invalid_request"`
- **AND** neither change is stored

#### Scenario: Unknown field
- **WHEN** a client pushes a memo with an extra field `mood`
- **THEN** the change is applied and pulled records do not contain `mood`

### Requirement: Per-account isolation
Sync endpoints SHALL require a bearer session, and SHALL read and write only the records of the account that owns the session.

#### Scenario: Another account's records are invisible
- **WHEN** account A pushes a memo and account B pulls from version 0
- **THEN** B's pull does not contain A's memo

#### Scenario: No session
- **WHEN** a client calls a sync endpoint without a valid token
- **THEN** the response status is 401 with `error.code` equal to `"unauthorized"`

### Requirement: Push with last-write-wins
`POST /api/v1/sync/push` SHALL accept a `deviceId` (1–64 chars) and 1–500 changes. For each change in order, the server SHALL apply it if no record with that type and id exists, or if its (`updatedAt`, `deviceId`) is greater than the stored record's (compared by `updatedAt`, then `deviceId` as a string). Each applied change SHALL receive the next account version (versions increase by one per applied change). The response SHALL list, for every change, `status` `"applied"` or `"stale"` and the record's current `version`, plus the account's latest `version`.

#### Scenario: Newer change wins
- **WHEN** device A pushes a memo with `updatedAt` 1000 and device B later pushes the same memo with `updatedAt` 2000
- **THEN** B's change is `"applied"` and a pull returns B's fields

#### Scenario: Older change is stale
- **WHEN** a record has `updatedAt` 2000 and a client pushes the same record with `updatedAt` 1000
- **THEN** the change is `"stale"` and the stored record is unchanged

#### Scenario: Tie broken by device id
- **WHEN** devices `"a"` and `"b"` push the same record with the same `updatedAt`
- **THEN** device `"b"`'s change is the stored one regardless of arrival order

#### Scenario: Re-pushing is idempotent
- **WHEN** a client pushes exactly the same change twice
- **THEN** the second push reports `"stale"` and the account version does not change

#### Scenario: Too many changes
- **WHEN** a push contains 501 changes
- **THEN** the response status is 400 with `error.code` equal to `"invalid_request"`

### Requirement: Tombstones
A change with a non-null `deletedAt` SHALL turn the record into a tombstone that keeps its id, `updatedAt`, `deletedAt`, `deviceId`, and version but no field values. Tombstones SHALL be returned by pulls. A later change that wins last-write-wins SHALL replace a tombstone, including one with a null `deletedAt`.

#### Scenario: Deletion reaches other devices
- **WHEN** device A deletes a memo and device B pulls
- **THEN** B receives the memo with a non-null `deletedAt` and no fields

#### Scenario: Newer edit restores a deleted record
- **WHEN** a memo was deleted at `updatedAt` 2000 and another device pushes it with `updatedAt` 3000 and `deletedAt` null
- **THEN** the memo is stored with that device's fields and is no longer a tombstone

### Requirement: Clock handling
The server SHALL store an `updatedAt` that is more than 5 minutes later than the server's clock as the server's current time, so that a device with a fast clock cannot make its changes win indefinitely.

#### Scenario: Future timestamp
- **WHEN** a client pushes a change with `updatedAt` one day in the future
- **THEN** the stored `updatedAt` is no later than the server time at which the push was handled

### Requirement: Pull changes since a version
`GET /api/v1/sync/pull?since=<version>&limit=<n>` SHALL return, in ascending version order, the current state of every record whose version is greater than `since`: its type, id, `version`, `updatedAt`, `deletedAt`, `deviceId`, and `fields` (omitted for tombstones). It SHALL also return the account's latest `version` and `hasMore`. `limit` SHALL default to 500 and SHALL NOT exceed 1,000. Each record SHALL appear at most once, at its latest version.

#### Scenario: Full pull
- **WHEN** a client pulls with `since=0`
- **THEN** it receives every record of the account, including tombstones

#### Scenario: Incremental pull
- **WHEN** a client pulls with `since` equal to the version it last saw, after another device applied two changes
- **THEN** it receives exactly those two records

#### Scenario: Pagination
- **WHEN** more records changed than `limit`
- **THEN** the response has `hasMore` true, and pulling again from the last returned version returns the rest

### Requirement: Change notifications over WebSocket
`GET /api/v1/sync/ws` with a bearer session SHALL upgrade to a WebSocket. The server SHALL send `{"type":"version","version":<n>}` when the socket opens, and to every open socket of the account after a push that applies at least one change. Clients SHALL use these messages only as a signal to pull.

#### Scenario: Another device is notified
- **WHEN** device B has an open socket and device A pushes a change that is applied
- **THEN** B receives a `version` message with the new account version

#### Scenario: Stale push sends no notification
- **WHEN** a push applies no changes
- **THEN** no `version` message is sent

### Requirement: Conformance fixtures
`contract/sync-fixtures/` SHALL contain JSON scenarios (sequences of pushes and pulls with expected results) that define protocol behavior independently of any implementation. The server test suite SHALL execute every fixture file in that directory, and a failing expectation SHALL fail the suite.

#### Scenario: New fixture is executed
- **WHEN** a developer adds a fixture file
- **THEN** the next server test run executes it without further registration
