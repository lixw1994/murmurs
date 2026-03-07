import XCTest
@testable import Murmurs

final class DateHelperExtendedTests: XCTestCase {

    // MARK: - components(from:)

    func testComponents_FromValidIdentifier() {
        let components = DateHelper.components(from: 20230715)
        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 7)
        XCTAssertEqual(components.day, 15)
    }

    func testComponents_FromDecemberDate() {
        let components = DateHelper.components(from: 20231225)
        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 12)
        XCTAssertEqual(components.day, 25)
    }

    // MARK: - date(from:)

    func testDate_FromValidIdentifier_ReturnsNonNil() {
        let date = DateHelper.date(from: 20230715)
        XCTAssertNotNil(date)
    }

    // MARK: - format()

    func testFormat_WithCustomDateFormat() {
        let date = DateHelper.date(from: 20230715)!
        let formatted = DateHelper.format(date, dateFormat: "yyyy-MM-dd")
        XCTAssertEqual(formatted, "2023-07-15")
    }

    func testFormat_WithDefaultFormat() {
        let date = DateHelper.date(from: 20230715)!
        let formatted = DateHelper.format(date)
        XCTAssertFalse(formatted.isEmpty)
    }

    // MARK: - formatIdentifier()

    func testFormatIdentifier_WithCustomFormat() {
        let formatted = DateHelper.formatIdentifier(20230715, dateFormat: "yyyy/MM/dd")
        XCTAssertEqual(formatted, "2023/07/15")
    }

    // MARK: - timeToDate()

    func testTimeToDate_ReturnsDateWithCorrectComponents() {
        let date = DateHelper.timeToDate(h: 14, m: 30, s: 45)
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.hour, from: date), 14)
        XCTAssertEqual(calendar.component(.minute, from: date), 30)
        XCTAssertEqual(calendar.component(.second, from: date), 45)
    }

    func testTimeToDate_WithZeroValues() {
        let date = DateHelper.timeToDate(h: 0, m: 0, s: 0)
        let calendar = Calendar.current
        XCTAssertEqual(calendar.component(.hour, from: date), 0)
        XCTAssertEqual(calendar.component(.minute, from: date), 0)
    }
}
