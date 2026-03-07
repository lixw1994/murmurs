## 1. Model Type

- [x] 1.1 Replace `OpenAIChatModel` enum in `Sources/Models/OpenAIChatModel.swift` with `ChatModel` struct (id, displayName, presets, default, custom init). Verify: build succeeds.
- [x] 1.2 Update `ConfigProtocol` in `Sources/Services/Protocols/ConfigProtocol.swift` — change `aiModel` type from `OpenAIChatModel` to `ChatModel`. Verify: build succeeds.

## 2. Config & Storage

- [x] 2.1 Update `Config.swift` — replace `@AppStorage("openai_model") var aiModel = OpenAIChatModel.gpt_3_5` with JSON-backed `ChatModel` storage using new key `"chat_model"`. Add migration logic to read legacy `"openai_model"` enum values and map to new model IDs. Verify: build succeeds.
- [x] 2.2 Update `MockConfig` in `Tests/Mocks/` to use `ChatModel` type. Verify: build succeeds.

## 3. API Layer

- [x] 3.1 Update `AIClientProtocol` — change `model: OpenAIChatModel` to `model: ChatModel` in `summarize`, `polish`, `verify` methods. Verify: build succeeds.
- [x] 3.2 Update `OpenAIClient` — use `model.id` instead of `model.name` in API request bodies. Verify: build succeeds.
- [x] 3.3 Update `MockAIClient` in `Tests/Mocks/` to match new protocol signatures. Verify: build succeeds.

## 4. ViewModels

- [x] 4.1 Update `AddSummaryViewModel` — change `model` property type to `ChatModel`. Verify: build succeeds.
- [x] 4.2 Update `TimelineViewModel.polish()` — adapt to `ChatModel`. Verify: build succeeds.
- [x] 4.3 Update `ServerSettingsViewModel` — adapt verify call to `ChatModel`. Verify: build succeeds.

## 5. Settings UI

- [x] 5.1 Update `SettingsView` model picker — show preset list with a "Custom" option. When custom is selected, show a TextField for entering model ID. Verify: build succeeds.

## 6. Tests

- [x] 6.1 Update existing tests that reference `OpenAIChatModel` to use `ChatModel`. Verify: all tests pass.
