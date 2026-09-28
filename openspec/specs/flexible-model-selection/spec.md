## Purpose

Let users choose the chat model from a preset list or enter a custom model ID for OpenAI-compatible providers.

## Requirements

### Requirement: Preset model list

The app SHALL provide a curated list of preset chat models covering current OpenAI and popular OpenAI-compatible models.

#### Scenario: User views model picker
- **WHEN** user opens Settings → Summarization → Model picker
- **THEN** a list of preset models is displayed with human-readable names
- **AND** the list includes at minimum: GPT-4o mini, GPT-4o, GPT-4.1 nano, GPT-4.1 mini, GPT-4.1, GPT-5 nano, GPT-5 mini, GPT-5, GPT-5.4

### Requirement: Custom model ID input

Users SHALL be able to enter any arbitrary model ID string to use models not in the preset list.

#### Scenario: User selects custom model
- **WHEN** user selects "Custom" in the model picker
- **THEN** a text field appears for entering a model ID
- **AND** the entered ID is used directly in API calls

#### Scenario: User has a non-preset model selected
- **WHEN** the stored model ID does not match any preset
- **THEN** the picker shows the custom option as selected
- **AND** the text field displays the current custom model ID

### Requirement: Model ID sent to API

The selected model's ID string SHALL be sent as the `model` field in chat completion requests.

#### Scenario: Summarize with selected model
- **WHEN** user triggers summarization
- **THEN** the API request body contains `"model": "<selected-model-id>"`

#### Scenario: Polish with selected model
- **WHEN** user triggers text polish
- **THEN** the API request body contains `"model": "<selected-model-id>"`

### Requirement: Default model

New installations SHALL default to `gpt-4o-mini`.

#### Scenario: Fresh install
- **WHEN** user has never selected a model
- **THEN** `gpt-4o-mini` is used for all API calls

### Requirement: Migration from legacy enum

Existing users who have a model selected via the old enum-based storage MUST be migrated seamlessly.

#### Scenario: Existing user upgrades
- **WHEN** app launches with legacy `openai_model` AppStorage key
- **THEN** the old enum value is mapped to the corresponding model ID string
- **AND** the new storage key is populated
- **AND** the old key is cleaned up
