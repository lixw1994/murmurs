## MODIFIED Requirements

### Requirement: Delete the account
`DELETE /api/v1/me` SHALL permanently delete the authenticated account, all of its sessions, its recovery code, and all of its synced records, and return HTTP 204.

#### Scenario: Deleted account is unusable
- **WHEN** a client deletes its account
- **THEN** every token of that account returns 401
- **AND** recovering with the account's recovery code fails with `invalid_recovery_code`

#### Scenario: Synced data is deleted
- **WHEN** an account that has synced memos is deleted
- **THEN** the account's synced storage contains no records
