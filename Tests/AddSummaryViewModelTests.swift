import XCTest
import SwiftData
@testable import Murmurs

@MainActor
final class AddSummaryViewModelTests: XCTestCase {
    var container: DataContainer!
    var mockAIClient: MockAIClient!
    var mockStore: MockMemoStore!
    var mockConfig: MockConfig!

    override func setUp() {
        container = DataContainer(inMemory: true)
        mockAIClient = MockAIClient()
        mockStore = MockMemoStore(context: container.context)
        mockConfig = MockConfig()
        mockConfig.isServerValid = true
        mockConfig.serverHost = "http://localhost"
    }

    private func makeVM() -> AddSummaryViewModel {
        let dayId = DateHelper.todayIdentifier()
        return AddSummaryViewModel(
            item: .day(dayId),
            context: container.context,
            aiClient: mockAIClient,
            store: mockStore,
            config: mockConfig
        )
    }

    private func makeMemo(content: String, day: Int32) -> MemoEntity {
        let memo = MemoEntity(content: content, day: day)
        container.context.insert(memo)
        return memo
    }

    private func makePrompt(title: String, content: String, temperature: Double = 0.5) -> PromptEntity {
        let prompt = PromptEntity(title: title, content: content, temperature: temperature)
        container.context.insert(prompt)
        return prompt
    }

    // MARK: - replacePlaceHolders()

    func testReplacePlaceHolders_ReplacesDatePlaceholder() {
        let vm = makeVM()
        let result = vm.replacePlaceHolders("Report for {{date}}")
        let expected = "Report for \(DateHelper.formatIdentifier(vm.dayId))"
        XCTAssertEqual(result, expected)
    }

    func testReplacePlaceHolders_NoPlaceholder_ReturnsOriginal() {
        let vm = makeVM()
        let result = vm.replacePlaceHolders("No placeholders here")
        XCTAssertEqual(result, "No placeholders here")
    }

    // MARK: - fetchEntries()

    func testFetchEntries_PopulatesValidMemosAndContent() throws {
        let dayId = Int32(DateHelper.todayIdentifier())
        _ = makeMemo(content: String(repeating: "Hello world. ", count: 5), day: dayId)
        try container.context.save()

        let vm = AddSummaryViewModel(
            item: .day(Int(dayId)),
            context: container.context,
            aiClient: mockAIClient,
            store: mockStore,
            config: mockConfig
        )
        vm.fetchEntries()

        XCTAssertFalse(vm.validMemos.isEmpty)
        XCTAssertFalse(vm.memoContent.isEmpty)
        XCTAssertTrue(vm.memoContent.contains("Hello world."))
    }

    func testFetchEntries_WhenNoValidMemos_SetsFatalError() {
        let emptyDay: Int32 = 19000101

        let vm = AddSummaryViewModel(
            item: .day(Int(emptyDay)),
            context: container.context,
            aiClient: mockAIClient,
            store: mockStore,
            config: mockConfig
        )
        vm.fetchEntries()

        XCTAssertTrue(vm.showFatalError)
    }

    func testFetchEntries_FiltersEmptyContent() throws {
        let uniqueDay: Int32 = 19000102
        _ = makeMemo(content: "", day: uniqueDay)
        _ = makeMemo(content: String(repeating: "Valid content. ", count: 5), day: uniqueDay)
        try container.context.save()

        let vm = AddSummaryViewModel(
            item: .day(Int(uniqueDay)),
            context: container.context,
            aiClient: mockAIClient,
            store: mockStore,
            config: mockConfig
        )
        vm.fetchEntries()

        XCTAssertEqual(vm.validMemos.count, 1)
    }

    // MARK: - generateMessage()

    func testGenerateMessage_WithPrompt_BuildsMessage() throws {
        let uniqueDay: Int32 = 19000103
        _ = makeMemo(content: String(repeating: "Test content. ", count: 5), day: uniqueDay)
        let prompt = makePrompt(title: "Test Prompt", content: "Summarize the following for {{date}}:")
        try container.context.save()

        let vm = AddSummaryViewModel(
            item: .day(Int(uniqueDay)),
            context: container.context,
            aiClient: mockAIClient,
            store: mockStore,
            config: mockConfig
        )
        vm.fetchEntries()
        vm.selectedPrompt = prompt
        vm.generateMessage()

        XCTAssertTrue(vm.summaryMessage.contains("------"))
        XCTAssertTrue(vm.summaryMessage.contains("Test content."))
        XCTAssertFalse(vm.summaryMessage.contains("{{date}}"))
    }

    func testGenerateMessage_WithoutPrompt_DoesNothing() {
        let vm = makeVM()
        vm.selectedPrompt = nil
        vm.generateMessage()
        XCTAssertTrue(vm.summaryMessage.isEmpty)
    }

    // MARK: - summarize()

    func testSummarize_CallsAIClientAndSetsResponse() async {
        mockAIClient.summarizeResult = ["Hello", " World"]
        let vm = makeVM()
        vm.summaryMessage = "Test message"

        vm.summarize()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertTrue(mockAIClient.summarizeCalled)
        XCTAssertEqual(mockAIClient.lastSummarizeMsg, "Test message")
        XCTAssertEqual(vm.summarizedResponse, "Hello World")
        XCTAssertFalse(vm.isSummarizing)
    }

    func testSummarize_RecordsUsage() async {
        mockAIClient.summarizeResult = ["Response"]
        let vm = makeVM()
        vm.summaryMessage = "Test message"

        vm.summarize()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertTrue(mockStore.recordUsageCalled)
        XCTAssertEqual(mockStore.lastCharsSent, vm.summaryMessageCharCount)
    }

    func testSummarize_OnError_SetsSummaryError() async {
        mockAIClient.summarizeError = URLError(.badServerResponse)
        let vm = makeVM()
        vm.summaryMessage = "Test message"

        vm.summarize()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertFalse(vm.summaryError.isEmpty)
        XCTAssertFalse(vm.isSummarizing)
    }

    func testSummarize_WhenAlreadySummarizing_DoesNothing() async {
        let vm = makeVM()
        vm.isSummarizing = true
        let callCountBefore = mockAIClient.summarizeCallCount

        vm.summarize()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(mockAIClient.summarizeCallCount, callCountBefore)
    }

    // MARK: - save()

    func testSave_CreatesSummaryEntity() throws {
        let vm = makeVM()
        vm.summarizedResponse = "Generated summary"

        let descriptor = FetchDescriptor<SummaryEntity>()
        let initialCount = try container.context.fetch(descriptor).count

        vm.save()

        let results = try container.context.fetch(descriptor)
        XCTAssertEqual(results.count, initialCount + 1)
        let saved = results.first { $0.content == "Generated summary" }
        XCTAssertNotNil(saved)
        XCTAssertTrue(vm.saved)
    }

    // MARK: - selectedPrompt didSet

    func testSelectedPrompt_SetsTemperature() throws {
        let vm = makeVM()
        let prompt = makePrompt(title: "Test", content: "Test", temperature: 0.8)
        try container.context.save()

        vm.selectedPrompt = prompt
        XCTAssertEqual(vm.temperature, 0.8)
    }

    // MARK: - summaryMessageCharCount

    func testSummaryMessageCharCount_TracksMessageLength() {
        let vm = makeVM()
        vm.summaryMessage = "12345"
        XCTAssertEqual(vm.summaryMessageCharCount, 5)
    }
}
