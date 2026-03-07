import XCTest
import SwiftData
@testable import Murmurs

@MainActor final class ExporterTests: XCTestCase {
    var container: DataContainer!

    override func setUp() {
        container = DataContainer(inMemory: true)
    }

    func testExportMemos_ReturnsMarkdownWithMemoContent() throws {
        let dayId = DateHelper.todayIdentifier()
        let memo = MemoEntity(content: "Export test content", day: Int32(dayId))
        container.context.insert(memo)
        try container.context.save()

        let result = Exporter.exportMemos(dayId, context: container.context)

        XCTAssertTrue(result.contains("Export test content"))
        XCTAssertTrue(result.contains("# "))
    }

    func testExportMemos_FiltersEmptyContent() throws {
        let dayId = DateHelper.todayIdentifier()
        let memo1 = MemoEntity(content: "", day: Int32(dayId))
        container.context.insert(memo1)
        let memo2 = MemoEntity(content: "Has content", day: Int32(dayId))
        container.context.insert(memo2)
        try container.context.save()

        let result = Exporter.exportMemos(dayId, context: container.context)

        XCTAssertTrue(result.contains("Has content"))
    }

    func testExportMemos_NoMemosForDay_ReturnsHeaderOnly() {
        let result = Exporter.exportMemos(99990101, context: container.context)
        XCTAssertTrue(result.hasPrefix("# "))
        XCTAssertFalse(result.contains("## "))
    }
}
