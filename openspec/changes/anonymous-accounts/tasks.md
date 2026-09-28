## 1. Server: Better Auth and data model

- [ ] 1.1 `getAuth(db, env)` reads the secret and base URL from `env`; enable `anonymous` (`emailDomainName`) and `bearer` plugins; `disabledPaths`; session `expiresIn` 365 days. Update `server-entry.ts` and the auth route. Verify: `pnpm --dir web check`
- [ ] 1.2 Add `isAnonymous` to the user schema and the `recovery_code` table; `pnpm --dir web db:generate --name anonymous_accounts`. Verify: `pnpm --dir web db:migrate:local` applies 0001; running again applies nothing
- [ ] 1.3 Recovery code module: generate, normalize, format, hash. Verify: unit tests in `web/test/recovery-code.test.ts`

## 2. Server: /api/v1 account endpoints

- [ ] 2.1 Add `ratelimits` bindings (dev, staging, production) and run `wrangler types`. Verify: `pnpm --dir web check`
- [ ] 2.2 New error codes, the `bearerAuth` security scheme, and the `requireSession` middleware. Verify: `pnpm --dir web check`
- [ ] 2.3 `POST /accounts` and `POST /sessions/recover` with rate limits. Verify: tests 3.1
- [ ] 2.4 `GET /me`, `POST /me/recovery-code`, `DELETE /sessions/current`, `DELETE /me`. Verify: tests 3.1

## 3. Server tests and contract

- [ ] 3.1 `web/test/accounts.test.ts` covering every `anonymous-accounts` scenario (create, code format, lenient input, no plaintext, missing and unknown token, session lifetime, recovery, wrong code, rate limit, me, rotation, sign-out, deletion); update `auth.test.ts` for the closed Better Auth routes including anonymous sign-in. Verify: `pnpm --dir web test`
- [ ] 3.2 Regenerate the contract. Verify: `check-drift.sh` passes; `BASE_REF=HEAD contract/scripts/check-breaking.sh` reports no breaking changes

## 4. iOS: API package

- [ ] 4.1 Move `contract/consumers/swift` to `apple/Packages/MurmursAPI` (symlinked `openapi.json`, add `swift-openapi-urlsession`); point `check-generators.sh swift` and `contract.yml` at it. Verify: `contract/scripts/check-generators.sh swift`
- [ ] 4.2 Add the package to `project.yml`; add the `MURMURS_API_BASE_URL` build setting per configuration and the Info.plist key; add `-skipPackagePluginValidation` to the Fastlane `tests` lane. Verify: `cd apple && xcodegen && xcodebuild build … -skipPackagePluginValidation` succeeds

## 5. iOS: account logic

- [ ] 5.1 `CredentialStore` protocol and `KeychainCredentialStore` (device-only token, synchronizable recovery code). Verify: Apple build
- [ ] 5.2 `AccountAPI` protocol and the generated-client implementation with the bearer middleware and error mapping. Verify: Apple build
- [ ] 5.3 `AccountService` (`ensureAccount`, `restore`, `rotateRecoveryCode`, `deleteAccount`, `refreshAfterUnauthorized`). Verify: Apple build
- [ ] 5.4 Unit tests with `MockAccountAPI` and `MockCredentialStore`: first launch creates; stored code restores; offline leaves `.none`; unauthorized recovers once; failed recovery gives `.needsRestore` without creating a new account; invalid restore keeps the current account; delete clears credentials. Verify: `xcodebuild test`
- [ ] 5.5 Trigger `ensureAccount()` when the scene becomes active, skipped for SNAPSHOT and XCTest. Verify: Apple build and tests

## 6. iOS: Account settings UI

- [ ] 6.1 Add Account strings to `l10n/Localizable.csv` (`apple`); run `rake l10n`. Verify: `ruby l10n/test_generate.rb`; Apple build
- [ ] 6.2 `AccountViewModel` and `AccountSettingsView` (reveal and copy, rotate with confirmation, restore, delete with confirmation, no-account and needs-restore states); an Account section in `SettingsView`. Verify: Apple build; view model unit tests pass

## 7. Deploy and document

- [ ] 7.1 Apply migration 0001 to staging and deploy; exercise create, me, recover, rotate, sign-out, delete, and the rate limit against `https://murmurs-staging.denkit.app`. Verify: responses match the spec
- [ ] 7.2 Update CLAUDE.md and `openspec/config.yaml` (Apple commands with `-skipPackagePluginValidation`, accounts in context), `docs/architecture.md` (accounts, iOS API package), `docs/roadmap.md` (P0), README if affected. Verify: `openspec validate --all --strict`
- [ ] 7.3 Full verification sweep: web check, test, and build; contract drift, breaking, and generator checks; `rake l10n` idempotent; Apple build and tests; specs
