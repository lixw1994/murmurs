import XCTest
import SwiftData
@testable import Murmurs

@MainActor final class ExportViewModelTests: XCTestCase {
    var container: DataContainer!

    override func setUp() {
        container = DataContainer(inMemory: true)
    }

    // MARK: - genRows() for notes

    func testGenRows_WithNotes_ReturnsHeaderAndData() throws {
        let memo = MemoEntity(content: "Test content", day: Int32(DateHelper.todayIdentifier()))
        container.context.insert(memo)
        try container.context.save()

        let vm = ExportViewModel(context: container.context)
        vm.category = .note
        let rows = try vm.genRows()

        XCTAssertGreaterThan(rows.count, 1)
        XCTAssertEqual(rows[0], ["time", "content"])
        let hasTestContent = rows.contains { $0.contains("Test content") }
        XCTAssertTrue(hasTestContent)
    }

    func testGenRows_ForSummary_ReturnsThreeColumns() throws {
        let summary = SummaryEntity(title: "Test Title", content: "Test Body")
        container.context.insert(summary)
        try container.context.save()

        let vm = ExportViewModel(context: container.context)
        vm.category = .summary
        let rows = try vm.genRows()

        XCTAssertEqual(rows[0], ["time", "title", "content"])
        let hasSummary = rows.contains { $0.contains("Test Title") && $0.contains("Test Body") }
        XCTAssertTrue(hasSummary)
    }

    // MARK: - genMarkdownContent()

    func testGenMarkdownContent_WithNotes_ContainsMemoContent() throws {
        let memo = MemoEntity(content: "Markdown test content", day: Int32(DateHelper.todayIdentifier()))
        container.context.insert(memo)
        try container.context.save()

        let vm = ExportViewModel(context: container.context)
        vm.category = .note
        let markdown = try vm.genMarkdownContent()

        XCTAssertTrue(markdown.contains("Markdown test content"))
        XCTAssertTrue(markdown.contains("###"))
    }
}
