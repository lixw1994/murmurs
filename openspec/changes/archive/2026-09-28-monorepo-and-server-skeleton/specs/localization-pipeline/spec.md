## ADDED Requirements

### Requirement: Single localization source
`l10n/Localizable.csv` SHALL be the only source of user-facing strings for the Apple app and the web app, with the columns `key`, `comment`, `platforms`, `en`, and `zh-Hans`. Generated localization files SHALL NOT be edited by hand.

#### Scenario: Web strings come from the CSV
- **WHEN** a developer needs a new user-facing string in the web UI
- **THEN** the developer adds it to `l10n/Localizable.csv` and regenerates
- **AND** no string is added directly to a web locale file

### Requirement: One command generates all platforms
A single documented command SHALL regenerate the Apple outputs (the `LocalizedKeys.swift` key enum and the `en` and `zh-Hans` `.strings` files) and the web outputs (one locale resource per CSV language). Generation SHALL be deterministic: running it twice without CSV changes SHALL produce no file changes.

#### Scenario: Regenerate after editing the CSV
- **WHEN** a developer edits a translation in the CSV and runs the generation command
- **THEN** the Apple `.strings` files and the web locale resources both contain the new translation

#### Scenario: Deterministic output
- **WHEN** the generation command runs twice in a row without CSV changes
- **THEN** the second run changes no files

### Requirement: Platform-scoped keys
The `platforms` column SHALL declare whether a key is used by the Apple app (`apple`), the web app (`web`), or both (`apple web`). Each platform's generated output SHALL contain exactly the keys that apply to that platform. Generation SHALL fail when a key row has an empty or unknown `platforms` value.

#### Scenario: Web-only key
- **WHEN** a key's `platforms` value is `web`
- **THEN** it appears in the web locale resources
- **AND** it does not appear in `LocalizedKeys.swift` or the `.strings` files

#### Scenario: Shared key
- **WHEN** a key's `platforms` value is `apple web`
- **THEN** it appears in both the Apple and the web outputs with the same translations

#### Scenario: Missing platforms value
- **WHEN** a key row has an empty `platforms` value
- **THEN** generation fails and names the key

### Requirement: Placeholders work on each platform
Strings with format placeholders SHALL render with their arguments substituted on each platform. Literal template text that looks like interpolation, such as `{{date}}` in prompt templates, SHALL render unchanged on the web.

#### Scenario: Formatted string on the web
- **WHEN** the web UI renders a string that contains a `%@` or `%d` placeholder in the CSV and supplies its arguments
- **THEN** the arguments appear in place of the placeholders

#### Scenario: Literal double braces on the web
- **WHEN** the web UI renders a string whose CSV text contains `{{date}}`
- **THEN** the text `{{date}}` is shown literally

### Requirement: Comment rows and missing translations
Rows whose key is a section comment (such as `# Plist #`) SHALL NOT produce keys. When a key has no translation for a language, generation SHALL report that key and language.

#### Scenario: Section comment row
- **WHEN** the CSV contains a section comment row
- **THEN** no key is generated for it on any platform

#### Scenario: Missing translation
- **WHEN** a key has an English value but an empty `zh-Hans` value
- **THEN** the generation command reports the key as missing a `zh-Hans` translation
