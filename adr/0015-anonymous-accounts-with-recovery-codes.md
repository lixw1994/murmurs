# ADR-0015: Start with anonymous accounts and recovery codes; defer social sign-in

- Status: accepted, supersedes ADR-0011
- Date: 2026-09-28
- Supersedes: ADR-0011
- Deciders: project owner, Tech Lead

## Context and Problem Statement

ADR-0011 chose Sign in with Apple, Google, and email OTP through Better Auth as the way to create accounts. Before building it, the owner decided that launch should need no sign-in at all: a voice journal should let people record on first launch. Accounts are still required, because sync, the server-side pipeline, and quotas need an owner for every piece of data (ADR-0002, ADR-0005). The domain is now fixed (`murmurs.denkit.app`, staging `murmurs-staging.denkit.app`). The product is pre-launch, so no existing accounts are affected.

## Considered Options

- Anonymous accounts created automatically, recoverable with a high-entropy recovery code; the iOS app keeps the code in iCloud Keychain; social sign-in added later
- Social and email sign-in as in ADR-0011
- Anonymous accounts without any recovery path

## Decision Outcome

Chosen option: "Anonymous accounts with recovery codes", because it removes sign-in from first launch, and it still gives every user a way to move to a new device. The recovery code works manually anywhere, and automatically across devices on the same Apple ID through iCloud Keychain. Better Auth remains the user and session store with its `anonymous` and `bearer` plugins, so social sign-in and account linking can be added without migrating users. Accounts are created and restored only through `/api/v1` (ADR-0004).

### Consequences

- Good, because users start recording with no sign-in screen.
- Good, because Sign in with Apple is not required by App Store rules while no third-party sign-in is offered.
- Good, because Better Auth's anonymous plugin keeps a path to link real identities later.
- Bad, because a user who loses the recovery code and has no iCloud Keychain copy cannot recover the account.
- Bad, because unauthenticated account creation must be rate-limited and later bounded by quotas.
- Required: account deletion (App Store) and recovery code rotation are part of the account API.
- Follow-up: social sign-in and linking become a separate change; the web gains account UI in P3.
