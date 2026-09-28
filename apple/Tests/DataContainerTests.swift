import XCTest
import SwiftData
@testable import Murmurs

@MainActor final class DataContainerTests: XCTestCase {
    var container: DataContainer!

    override func setUp() {
        container = DataContainer(inMemory: true)
    }

    func testAddMemo_CreatesMemoWithCorrectAttributes() throws {
        container.addMemo(content: "Test memo")

        let descriptor = FetchDescriptor<MemoEntity>()
        let results = try container.context.fetch(descriptor)
        let newMemo = results.first { $0.content == "Test memo" }
        XCTAssertNotNil(newMemo)
        XCTAssertNotNil(newMemo?.createdAt)
        XCTAssertEqual(newMemo?.timezone, TimeZone.current.identifier)
        XCTAssertGreaterThan(newMemo?.day ?? 0, 0)
    }

    func testDeleteMemo_RemovesMemo() throws {
        let memo = MemoEntity(content: "To delete")
        container.context.insert(memo)
        try container.context.save()

        container.deleteMemo(memo)

        let descriptor = FetchDescriptor<MemoEntity>()
        let results = try container.context.fetch(descriptor)
        XCTAssertFalse(results.contains(where: { $0.content == "To delete" }))
    }
}
