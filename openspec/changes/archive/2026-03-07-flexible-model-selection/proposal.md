## Why

The current model selection is hardcoded to 5 legacy OpenAI models (GPT-3.5-turbo, GPT-3.5-turbo-16k, GPT-4, GPT-4o, GPT-4o-mini). OpenAI has released many newer models (o1, o3, GPT-4.1, etc.), and users increasingly use OpenAI-compatible providers (DeepSeek, Ollama, Groq, etc.) with their own model IDs. The rigid enum prevents users from selecting newer or third-party models.

## What Changes

- Replace the hardcoded `OpenAIChatModel` enum with a flexible model system that combines built-in presets with user-defined custom model IDs
- Update the Settings UI model picker to show preset models and allow entering a custom model ID string
- Update the default model from `gpt-3.5-turbo` to `gpt-4o-mini`
- Store the selected model as a plain string (the model ID) instead of an enum raw value, with migration for existing users
- All API call sites continue to work unchanged — they just receive a string model ID

### Non-goals

- Validating whether a custom model ID actually exists on the server
- Auto-fetching available models from the API (`/v1/models` endpoint)
- Changing the Whisper transcription model selection
- Changing API base URL or authentication flows (already configurable)

## Capabilities

### New Capabilities
- `flexible-model-selection`: Flexible chat model selection with built-in presets and custom model ID input

### Modified Capabilities

_(none — no existing spec-level requirements change)_

## Impact

- `Sources/Models/OpenAIChatModel.swift` — replaced or significantly refactored
- `Sources/App/Config.swift` — model storage changes from enum to string
- `Sources/Services/OpenAI/OpenAIClient.swift` — accept string model ID instead of enum
- `Sources/Services/Protocols/AIClientProtocol.swift` — protocol signature updates
- `Sources/Services/Protocols/ConfigProtocol.swift` — model property type change
- `Sources/Modules/Settings/SettingsView.swift` — new model picker UI
- `Sources/Modules/Summary/AddSummaryViewModel.swift` — adapt to new model type
- `Sources/Modules/Timeline/TimelineViewModel.swift` — adapt to new model type
- `Sources/Modules/Settings/ServerSettingsViewModel.swift` — verify call update
- `Tests/` — mock updates for new signatures
