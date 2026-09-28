## REMOVED Requirements

### Requirement: Sign-in is disabled
**Reason**: Anonymous accounts are now created and restored through `/api/v1` (see the `anonymous-accounts` capability and the ADR that supersedes ADR-0011).
**Migration**: The remaining guarantees (Better Auth sign-up and sign-in routes stay closed; the web UI has no sign-in pages) move to the `anonymous-accounts` requirement "Accounts only through /api/v1".
