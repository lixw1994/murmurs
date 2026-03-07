import XCTest
import SwiftData
@testable import Murmurs

@MainActor final class QuickMemoViewModelTests: XCTestCase {
    var container: DataContainer!

    override func setUp() {
        container = DataContainer(inMemory: true)
    }

    func testSave_CreatesMemoEntity() throws {
        let descriptor = FetchDescriptor<MemoEntity>()
        let initialCount = try container.context.fetch(descriptor).count

        let vm = QuickMemoViewModel(context: container.context, notificationCenter: NotificationCenter())
        vm.content = "Test memo content"
        vm.save()

        let results = try container.context.fetch(descriptor)
        XCTAssertEqual(results.count, initialCount + 1)
        XCTAssertTrue(results.contains(where: { $0.content == "Test memo content" }))
    }

    func testSave_WithEmptyContent_StillCreatesEntity() throws {
        let descriptor = FetchDescriptor<MemoEntity>()
        let initialCount = try container.context.fetch(descriptor).count

        let vm = QuickMemoViewModel(context: container.context, notificationCenter: NotificationCenter())
        vm.content = ""
        vm.save()

        let results = try container.context.fetch(descriptor)
        XCTAssertEqual(results.count, initialCount + 1)
    }
}
