import XCTest
import SwiftData
@testable import Murmurs

@MainActor final class EditPromptViewModelTests: XCTestCase {
    var container: DataContainer!

    override func setUp() {
        container = DataContainer(inMemory: true)
    }

    func testNewPrompt_CanBeSaved_WhenTitleAndContentNotEmpty() {
        let vm = EditPromptViewModel(context: container.context)
        XCTAssertTrue(vm.newPrompt)
        XCTAssertFalse(vm.canBeSaved)

        vm.title = "Test"
        vm.content = "Content"

        XCTAssertTrue(vm.canBeSaved)
    }

    func testAdd_CreatesPromptEntity() throws {
        let vm = EditPromptViewModel(context: container.context)
        vm.title = "Test Prompt"
        vm.content = "Summarize the following: {{date}}"
        vm.temperature = 0.7
        vm.desc = "A test prompt"
        vm.add()

        let descriptor = FetchDescriptor<PromptEntity>()
        let results = try container.context.fetch(descriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Test Prompt")
        XCTAssertEqual(results.first?.temperature, 0.7)
    }

    func testDelete_RemovesPromptEntity() throws {
        let prompt = PromptEntity(title: "To Delete", content: "Content")
        container.context.insert(prompt)
        try container.context.save()

        let vm = EditPromptViewModel(prompt: prompt, context: container.context)
        vm.delete()

        let descriptor = FetchDescriptor<PromptEntity>()
        let results = try container.context.fetch(descriptor)
        XCTAssertEqual(results.count, 0)
    }
}
