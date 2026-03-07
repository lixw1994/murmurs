import XCTest
@testable import Murmurs

final class ErrorHelperTests: XCTestCase {

    func testDesc_WithLocalizedError_ReturnsErrorDescription() {
        let error = OpenAIError.badResponse("test")
        let desc = ErrorHelper.desc(error)
        XCTAssertEqual(desc, "Bad Response")
    }

    func testDesc_WithGenericError_ReturnsLocalizedDescription() {
        let error = URLError(.badURL)
        let desc = ErrorHelper.desc(error)
        XCTAssertFalse(desc.isEmpty)
    }
}
