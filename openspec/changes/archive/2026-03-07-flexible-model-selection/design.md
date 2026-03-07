## Context

Currently `OpenAIChatModel` is a `String`-backed enum with 5 hardcoded cases. The enum's `name` property provides the API model ID, and `displayName` provides the UI label. It's stored via `@AppStorage` and passed through `AIClientProtocol` methods.

## Goals / Non-Goals

**Goals:**
- Allow users to select from an updated list of preset models
- Allow users to enter any custom model ID string
- Keep the change minimal — same API call flow, just a flexible model identifier

**Non-Goals:**
- Fetching model lists from the server
- Validating custom model IDs
- Changing Whisper model handling

## Decisions

### 1. Replace enum with a struct-based approach

Replace `OpenAIChatModel` enum with a simple `ChatModel` struct:

```swift
struct ChatModel: Codable, Hashable {
    let id: String        // API model ID, e.g. "gpt-4o-mini"
    let displayName: String

    static let presets: [ChatModel] = [
        .init(id: "gpt-4o-mini", displayName: "GPT-4o mini"),
        .init(id: "gpt-4o", displayName: "GPT-4o"),
        .init(id: "gpt-4.1-nano", displayName: "GPT-4.1 nano"),
        .init(id: "gpt-4.1-mini", displayName: "GPT-4.1 mini"),
        .init(id: "gpt-4.1", displayName: "GPT-4.1"),
        .init(id: "gpt-5-nano", displayName: "GPT-5 nano"),
        .init(id: "gpt-5-mini", displayName: "GPT-5 mini"),
        .init(id: "gpt-5", displayName: "GPT-5"),
        .init(id: "gpt-5.4", displayName: "GPT-5.4"),
    ]

    static let `default` = presets[0]  // gpt-4o-mini

    // For custom user-entered model IDs
    init(id: String) {
        self.id = id
        self.displayName = id
    }
}
```

**Rationale:** A struct is simpler than an enum for an open-ended set of values. Presets cover common models; custom input handles everything else.

### 2. Store as JSON string in AppStorage

`@AppStorage` doesn't natively support custom `Codable` types, so store the `ChatModel` as a JSON-encoded string with a computed property wrapper:

```swift
@AppStorage("chat_model") private var aiModelData: String = ""
var aiModel: ChatModel { get/set via JSON encode/decode }
```

**Migration:** On first access, if `aiModelData` is empty, check legacy key `"openai_model"` and map old enum values to new model IDs. Remove old key after migration.

### 3. Update API protocol to accept string model ID

Change `AIClientProtocol` methods from `model: OpenAIChatModel` to `model: ChatModel`. The API call uses `model.id` instead of `model.name`.

### 4. Settings UI: Picker + custom input

- Show preset models in a `Picker`
- Add an extra "Custom" option at the bottom
- When "Custom" is selected, show a `TextField` for entering the model ID
- If the current model doesn't match any preset, show it as selected in "Custom" mode

## Risks / Trade-offs

- **Migration correctness**: Old enum raw values (`gpt_3_5`, `gpt_4o_mini`) must map correctly to new string IDs. Mitigated by explicit mapping dictionary.
- **Custom model UX**: Users could enter invalid model IDs. Acceptable since verify-server already tests the connection and non-goals exclude validation.
