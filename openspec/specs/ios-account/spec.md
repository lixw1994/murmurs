## Purpose

Give the iOS app an account without any sign-in UI: create or restore it automatically, keep credentials in the Keychain (recovery code in iCloud Keychain), recover from rejected sessions, and let the user manage the account in Settings.

## Requirements

### Requirement: Automatic account on first launch
When the iOS app has no session token, it SHALL obtain one in the background without showing any sign-in screen: it SHALL restore the account with a stored recovery code if one is available, and otherwise create a new anonymous account. Recording and all local features SHALL work while no account exists. If the network is unavailable, the app SHALL retry when it next becomes active.

#### Scenario: First launch online
- **WHEN** the app launches for the first time with network access
- **THEN** it creates an anonymous account and stores its token and recovery code, without user interaction

#### Scenario: First launch offline
- **WHEN** the app launches for the first time without network access
- **THEN** the user can record memos
- **AND** the app creates the account the next time it becomes active with network access

### Requirement: Credential storage
The app SHALL store the session token in the Keychain as device-only (not synchronized), and the recovery code in the Keychain as synchronizable through iCloud Keychain. Neither value SHALL be stored in UserDefaults or logged.

#### Scenario: Restore on a new device with the same Apple ID
- **WHEN** the app is installed on a new device where iCloud Keychain has synchronized the recovery code
- **THEN** the app restores the existing account instead of creating a new one

### Requirement: Recovery after the session becomes invalid
When the API rejects the session token with `unauthorized`, the app SHALL try once to recover a new session with the stored recovery code. If that recovery fails, the app SHALL remove the token, keep the local data, and show in the Account section that the account needs to be restored; it SHALL NOT silently create a different account while a recovery code is stored.

#### Scenario: Expired session with a valid code
- **WHEN** the token is rejected and the stored recovery code is valid
- **THEN** the app obtains a new token without user interaction

#### Scenario: Recovery code no longer valid
- **WHEN** the token is rejected and recovery with the stored code fails
- **THEN** the Account section asks the user to restore with a recovery code

### Requirement: Account section in Settings
Settings SHALL contain an Account section that lets the user reveal and copy the recovery code (hidden until revealed), explains that the code is the only way to recover the account, rotates the recovery code after confirmation, restores a different account by entering a recovery code, and deletes the account after confirmation. When no account exists yet, the section SHALL say so.

#### Scenario: Copy the recovery code
- **WHEN** the user reveals the recovery code and taps copy
- **THEN** the formatted code is placed on the pasteboard

#### Scenario: Restore another account
- **WHEN** the user enters a valid recovery code in Restore
- **THEN** the app switches to that account and stores its token and recovery code

#### Scenario: Invalid code entered
- **WHEN** the user enters a code that the server rejects
- **THEN** the app shows an error and keeps the current account

#### Scenario: Delete the account
- **WHEN** the user confirms account deletion
- **THEN** the app deletes the account on the server and removes the token and recovery code from the Keychain
- **AND** memos stored on the device remain

### Requirement: API environment per build configuration
Debug builds SHALL call the staging API (`https://murmurs-staging.denkit.app`), and AppStore builds SHALL call the production API (`https://murmurs.denkit.app`). Snapshot builds and unit-test runs SHALL NOT create or restore accounts.

#### Scenario: Debug build
- **WHEN** a Debug build creates an account
- **THEN** the request goes to `https://murmurs-staging.denkit.app/api/v1/accounts`

#### Scenario: Unit tests
- **WHEN** the unit tests run in the app host
- **THEN** no account request is sent
