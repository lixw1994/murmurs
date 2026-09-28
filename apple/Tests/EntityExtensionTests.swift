import XCTest
import SwiftData
@testable import Murmurs

@MainActor final class EntityExtensionTests: XCTestCase {
    var container: DataContainer!

    override func setUp() {
        container = DataContainer(inMemory: true)
    }

    private func makeMemo(content: String? = nil) -> MemoEntity {
        let memo = MemoEntity(content: content)
        container.context.insert(memo)
        return memo
    }

    private func makeSummary(title: String = "", content: String = "") -> SummaryEntity {
        let summary = SummaryEntity(title: title, content: content)
        container.context.insert(summary)
        return summary
    }

    private func makePrompt(title: String = "", content: String = "", desc: String? = nil) -> PromptEntity {
        let prompt = PromptEntity(title: title, content: content, desc: desc)
        container.context.insert(prompt)
        return prompt
    }

    private func makeUsage(day: Int32 = 0) -> UsageEntity {
        let usage = UsageEntity(day: day)
        container.context.insert(usage)
        return usage
    }

    // MARK: - MemoEntity

    func testMemo_ViewContent_ReturnsContentOrEmpty() {
        let memo = makeMemo()
        XCTAssertEqual(memo.viewContent, "")
        memo.content = "Hello"
        XCTAssertEqual(memo.viewContent, "Hello")
    }

    func testMemo_ViewCreatedAt_FormatsDate() {
        let memo = makeMemo()
        memo.createdAt = DateHelper.date(from: 20230715)
        memo.timezone = TimeZone.current.identifier
        let result = memo.viewCreatedAt
        XCTAssertTrue(result.contains("2023"))
    }

    func testMemo_NewEntity_HasUUIDAndTimezone() {
        let memo = makeMemo()
        XCTAssertFalse(memo.entityId.isEmpty)
        XCTAssertEqual(memo.timezone, TimeZone.current.identifier)
    }

    // MARK: - SummaryEntity

    func testSummary_ViewTitle_ReturnsTitleOrEmpty() {
        let summary = makeSummary()
        XCTAssertEqual(summary.viewTitle, "")
        summary.title = "Daily Summary"
        XCTAssertEqual(summary.viewTitle, "Daily Summary")
    }

    func testSummary_ViewContent_ReturnsContentOrEmpty() {
        let summary = makeSummary()
        XCTAssertEqual(summary.viewContent, "")
        summary.content = "Some content"
        XCTAssertEqual(summary.viewContent, "Some content")
    }

    func testSummary_ShareContent_FormatsAsMarkdown() {
        let summary = makeSummary(title: "Title", content: "Body")
        XCTAssertEqual(summary.shareContent, "# Murmurs Title Summary\n\nBody")
    }

    func testSummary_TruncatedContent_TruncatesLongContent() {
        let summary = makeSummary(content: String(repeating: "a", count: 200))
        let truncated = summary.truncatedContent(50)
        XCTAssertTrue(truncated.hasSuffix("..."))
        XCTAssertEqual(truncated.count, 53)
    }

    func testSummary_TruncatedContent_KeepsShortContent() {
        let summary = makeSummary(content: "Short")
        let truncated = summary.truncatedContent(50)
        XCTAssertEqual(truncated, "Short")
    }

    // MARK: - PromptEntity

    func testPrompt_ViewTitle_ReturnsTitleOrEmpty() {
        let prompt = makePrompt()
        XCTAssertEqual(prompt.viewTitle, "")
        prompt.title = "My Prompt"
        XCTAssertEqual(prompt.viewTitle, "My Prompt")
    }

    func testPrompt_ViewContent_ReturnsContentOrEmpty() {
        let prompt = makePrompt()
        XCTAssertEqual(prompt.viewContent, "")
        prompt.content = "Summarize this"
        XCTAssertEqual(prompt.viewContent, "Summarize this")
    }

    func testPrompt_ViewDesc_ReturnsDescOrEmpty() {
        let prompt = makePrompt()
        XCTAssertEqual(prompt.viewDesc, "")
        prompt.desc = "A description"
        XCTAssertEqual(prompt.viewDesc, "A description")
    }

    // MARK: - UsageEntity

    func testUsage_ViewDay_WhenDayIsZero_ReturnsTodayIdentifier() {
        let usage = makeUsage(day: 0)
        XCTAssertEqual(usage.viewDay, DateHelper.todayIdentifier())
    }

    func testUsage_ViewDay_WhenDayIsSet_ReturnsDay() {
        let usage = makeUsage(day: 20230715)
        XCTAssertEqual(usage.viewDay, 20230715)
    }

    func testUsage_ViewCharsSent_ConvertsInt32() {
        let usage = makeUsage()
        usage.charsSent = 1500
        XCTAssertEqual(usage.viewCharsSent, 1500)
    }

    func testUsage_ViewCharsTotal_SumsSentAndReceived() {
        let usage = makeUsage()
        usage.charsSent = 100
        usage.charsReceived = 200
        XCTAssertEqual(usage.viewCharsTotal, 300)
    }

    func testUsage_ViewWisperDuration_ConvertsInt32() {
        let usage = makeUsage()
        usage.whisperDuration = 60
        XCTAssertEqual(usage.viewWisperDuration, 60)
    }

    // MARK: - MemoEntity (supplemental)

    func testMemo_ViewTime_FormatsHourMinute() {
        let memo = makeMemo()
        let calendar = Calendar.current
        memo.createdAt = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: Date())
        memo.timezone = TimeZone.current.identifier
        let result = memo.viewTime
        XCTAssertTrue(result.contains("14:30") || result.contains("2:30"))
    }

    func testMemo_UpdateCreationTime_UpdatesAttributes() {
        let memo = makeMemo()
        let newTime = DateHelper.date(from: 20230801)!
        memo.updateCreationTime(newTime)

        XCTAssertEqual(memo.createdAt, newTime)
        XCTAssertEqual(memo.timezone, TimeZone.current.identifier)
        XCTAssertGreaterThan(memo.day, 0)
    }

    func testMemo_UpdateCreationTime_SameTime_DoesNotUpdate() {
        let memo = makeMemo()
        let time = Date()
        memo.createdAt = time
        memo.timezone = "Asia/Tokyo"

        memo.updateCreationTime(time)
        XCTAssertEqual(memo.timezone, "Asia/Tokyo")
    }
}
