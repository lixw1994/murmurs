# ADR-0011: Authenticate with Sign in with Apple, Google, and email OTP through Better Auth

- Status: accepted
- Date: 2026-09-28
- Supersedes: —
- Deciders: project owner, Tech Lead

## Context and Problem Statement

Sync requires user accounts. The product targets markets outside mainland China. App Store rules require Sign in with Apple whenever other third-party sign-in options are offered. Native clients cannot rely on browser cookies, and the web client uses cookie sessions. The template already runs Better Auth on D1 with GitHub, Google, password, and Feishu providers.

## Considered Options

- Better Auth with Apple, Google, and email OTP; native clients exchange a platform ID token for a bearer token (`bearer()` plugin); the web uses cookie sessions
- Also offer password sign-in and GitHub
- A hosted identity provider (for example, Clerk)

## Decision Outcome

Chosen option: "Better Auth with Apple, Google, and email OTP", because it covers the target audiences with native sign-in flows, satisfies App Store rules, reuses the template's auth stack on D1, and avoids storing passwords.

### Consequences

- Good, because there is one auth system for native and web, with no password handling.
- Bad, because an Apple Services ID, Google OAuth clients per platform, and an email sending provider must be configured. The email provider is not yet chosen (Unknown).
- Follow-up: remove the GitHub, Feishu, and password providers from the template. The watch does not sign in separately; the phone uploads on its behalf.
