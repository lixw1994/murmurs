import Foundation
import SwiftData

@Model final class PromptEntity {
    var title: String = ""
    var content: String = ""
    var createdAt: Date?
    var desc: String?
    var temperature: Double = 0.0

    init(title: String = "", content: String = "", createdAt: Date = Date(), desc: String? = nil, temperature: Double = 0.5) {
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.desc = desc
        self.temperature = temperature
    }
}

extension PromptEntity {
    var viewTitle: String { title }
    var viewContent: String { content }
    var viewDesc: String { desc ?? "" }
}

#if DEBUG
extension PromptEntity {
    static func preview(context: ModelContext) -> PromptEntity {
        let p = PromptEntity(title: "Default", content: "........", desc: "Generate a summary of diary.")
        context.insert(p)
        return p
    }
}
#endif
