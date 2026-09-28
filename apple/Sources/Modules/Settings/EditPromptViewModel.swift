import Foundation
import SwiftData
import XLog
import Observation

@MainActor @Observable final class EditPromptViewModel {

    let prompt: PromptEntity?
    let context: ModelContext

    var title = ""
    var content = ""
    var temperature = 0.5
    var desc = ""
    var newPrompt = false

    var canBeSaved: Bool {
        guard !title.isEmpty, !content.isEmpty else { return false }
        guard let prompt else { return true }
        return title != prompt.viewTitle || content != prompt.viewContent || desc != prompt.viewDesc || temperature != prompt.temperature
    }

    init(prompt: PromptEntity? = nil, context: ModelContext = DataContainer.shared.context) {
        self.prompt = prompt
        self.context = context
        self.newPrompt = (prompt == nil)

        if let prompt {
            title = prompt.viewTitle
            content = prompt.viewContent
            temperature = prompt.temperature
            desc = prompt.viewDesc
        }
    }

    func add() {
        let prompt = PromptEntity(title: title, content: content, desc: desc, temperature: temperature)
        context.insert(prompt)
        save()
    }

    func update() {
        guard let prompt else { return }
        updateAttributes(prompt)
        save()
    }

    func delete() {
        guard let prompt else { return }
        context.delete(prompt)
        save()
    }

    private func updateAttributes(_ prompt: PromptEntity) {
        prompt.title = title
        prompt.desc = desc
        prompt.temperature = temperature
        prompt.content = content
    }

    private func save() {
        do {
            try context.save()
        } catch {
            XLog.error(error.localizedDescription, source: "Prompt")
        }
    }
}
