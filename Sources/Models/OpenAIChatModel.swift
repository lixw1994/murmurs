import Foundation

struct ChatModel: Codable, Hashable {
    let id: String
    let displayName: String

    init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
    }

    init(id: String) {
        self.id = id
        self.displayName = id
    }

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

    static let `default` = presets[0]

    var isPreset: Bool {
        ChatModel.presets.contains(self)
    }

    /// Map legacy enum raw values to model IDs
    static func fromLegacy(_ rawValue: String) -> ChatModel? {
        let mapping: [String: String] = [
            "gpt_3_5": "gpt-3.5-turbo",
            "gpt_3_5_16k": "gpt-3.5-turbo-16k",
            "gpt_4": "gpt-4",
            "gpt_4o_mini": "gpt-4o-mini",
            "gpt_4o": "gpt-4o",
        ]
        guard let modelId = mapping[rawValue] else { return nil }
        let preset = presets.first { $0.id == modelId }
        return preset ?? ChatModel(id: modelId)
    }
}
