import XCTest
import SwiftData
@testable import Murmurs

@MainActor final class TimelineViewModelTests: XCTestCase {
    var container: DataContainer!
    var mockTranscription: MockTranscriptionService!
    var mockConfig: MockConfig!
    var mockRecorder: MockAudioRecorder!
    var mockAIClient: MockAIClient!

    override func setUp() {
        container = DataContainer(inMemory: true)
        mockTranscription = MockTranscriptionService()
        mockConfig = MockConfig()
        mockRecorder = MockAudioRecorder()
        mockAIClient = MockAIClient()
    }

    private func makeVM() -> TimelineViewModel {
        TimelineViewModel(transcription: mockTranscription, context: container.context, config: mockConfig, recorder: mockRecorder, aiClient: mockAIClient)
    }

    private func makeMemo(file: String? = nil, content: String? = nil) -> MemoEntity {
        let memo = MemoEntity(content: content, file: file)
        container.context.insert(memo)
        try? container.context.save()
        return memo
    }

    // MARK: - transcribe()

    func testTranscribe_WhenFileExists_CallsService() {
        let vm = makeVM()
        let memo = makeMemo(file: "test.m4a")

        vm.transcribe(memo)

        XCTAssertTrue(mockTranscription.transcribeMemoCalled)
        XCTAssertEqual(mockTranscription.lastTranscribedMemo, memo)
    }

    func testTranscribe_WhenNoFile_DoesNotCallService() {
        let vm = makeVM()
        let memo = makeMemo()

        vm.transcribe(memo)

        XCTAssertFalse(mockTranscription.transcribeMemoCalled)
    }

    func testTranscribe_OnSuccess_UpdatesMemoContent() {
        mockTranscription.transcribeMemoResult = .success("Transcribed text")
        let vm = makeVM()
        let memo = makeMemo(file: "test.m4a", content: "")

        vm.transcribe(memo)

        XCTAssertEqual(memo.content, "Transcribed text")
        XCTAssertTrue(memo.transcribed)
        XCTAssertFalse(vm.transcribingMemos.contains(memo))
    }

    func testTranscribe_OnFailure_RecordsError() {
        let error = URLError(.badServerResponse)
        mockTranscription.transcribeMemoResult = .failure(error)
        let vm = makeVM()
        let memo = makeMemo(file: "test.m4a")

        vm.transcribe(memo)

        XCTAssertNotNil(vm.failedMemos[memo])
        XCTAssertFalse(vm.transcribingMemos.contains(memo))
    }

    // MARK: - toggleVisibility()

    func testToggleVisibility_TogglesHiddenState() throws {
        let vm = makeVM()
        let memo = makeMemo()
        memo.isHidden = false
        try container.context.save()

        vm.toggleVisibility(memo)
        XCTAssertTrue(memo.isHidden)

        vm.toggleVisibility(memo)
        XCTAssertFalse(memo.isHidden)
    }

    // MARK: - toggleMemoSelection()

    func testToggleMemoSelection_AddsAndRemoves() {
        let vm = makeVM()
        let memo = makeMemo()

        vm.toggleMemoSelection(memo)
        XCTAssertTrue(vm.selectedMemos.contains(memo))

        vm.toggleMemoSelection(memo)
        XCTAssertFalse(vm.selectedMemos.contains(memo))
    }

    // MARK: - deleteSelectedMemos()

    func testDeleteSelectedMemos_InMultiSelectMode_DeletesAll() throws {
        let vm = makeVM()
        let memo1 = makeMemo(content: "memo1")
        let memo2 = makeMemo(content: "memo2")

        vm.isMultiSelectMode = true
        vm.selectedMemos = Set([memo1, memo2])

        vm.deleteSelectedMemos(context: container.context)

        // Give asyncAfter time to complete
        let exp = expectation(description: "wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { exp.fulfill() }
        wait(for: [exp], timeout: 2)

        XCTAssertTrue(vm.selectedMemos.isEmpty)
        XCTAssertFalse(vm.isMultiSelectMode)
    }

    func testDeleteSelectedMemos_InSingleMode_DeletesOne() throws {
        let vm = makeVM()
        let memo = makeMemo(content: "to delete")

        vm.isMultiSelectMode = false
        vm.memoToDelete = memo

        vm.deleteSelectedMemos(context: container.context)

        XCTAssertNil(vm.memoToDelete)
    }

    // MARK: - memoToDelete didSet

    func testMemoToDelete_WhenSet_ShowsDeleteAlert() {
        let vm = makeVM()
        let memo = makeMemo()

        vm.memoToDelete = memo
        XCTAssertTrue(vm.showDeleteAlert)
    }

    // MARK: - beginHoldToRecord()

    func testBeginHoldToRecord_StartsRecordingAndSetsFlag() {
        let vm = makeVM()
        vm.beginHoldToRecord()

        XCTAssertTrue(mockRecorder.startRecordingCalled)
        XCTAssertTrue(vm.isHoldingToRecord)
    }

    // MARK: - endHoldToRecord()

    func testEndHoldToRecord_StopsRecording() throws {
        mockRecorder.voiceFile = URL(fileURLWithPath: "/tmp/test-hold.m4a")
        let vm = makeVM()
        vm.isHoldingToRecord = true

        vm.endHoldToRecord()

        XCTAssertFalse(vm.isHoldingToRecord)
        XCTAssertTrue(mockRecorder.stopRecordingCalled)
    }

    func testEndHoldToRecord_WhenNoVoiceFile_DoesNotCreateMemo() throws {
        mockRecorder.voiceFile = nil
        let vm = makeVM()

        let descriptor = FetchDescriptor<MemoEntity>()
        let initialCount = try container.context.fetch(descriptor).count
        vm.endHoldToRecord()

        let finalCount = try container.context.fetch(descriptor).count
        XCTAssertEqual(finalCount, initialCount)
    }

    // MARK: - cancelHoldToRecord()

    func testCancelHoldToRecord_TerminatesAndClearsFlag() {
        let vm = makeVM()
        vm.isHoldingToRecord = true

        vm.cancelHoldToRecord()

        XCTAssertTrue(mockRecorder.terminateCalled)
        XCTAssertFalse(vm.isHoldingToRecord)
    }

    // MARK: - handleMemoInserted

    func testHandleMemoInserted_WhenTransDisabled_DoesNotTranscribe() throws {
        mockConfig.transEnabled = false
        let vm = makeVM()

        let memo = makeMemo(file: "test-notify.m4a")
        memo.isFromWatch = true
        try container.context.save()
        NotificationCenter.default.post(name: .memoInserted, object: memo)

        XCTAssertFalse(mockTranscription.transcribeMemoCalled)
        _ = vm
    }

    func testHandleMemoInserted_WhenTransEnabled_TranscribesWatchMemo() throws {
        mockConfig.transEnabled = true
        let vm = makeVM()

        let memo = makeMemo(file: "test-notify.m4a")
        memo.isFromWatch = true
        try container.context.save()
        NotificationCenter.default.post(name: .memoInserted, object: memo)

        XCTAssertTrue(mockTranscription.transcribeMemoCalled)
        XCTAssertEqual(mockTranscription.lastTranscribedMemo, memo)
        _ = vm
    }

    // MARK: - polish()

    func testPolish_WhenServerNotSet_RecordsError() {
        mockConfig.isServerSet = false
        let vm = makeVM()
        let memo = makeMemo(content: "raw text")

        vm.polish(memo)

        XCTAssertNotNil(vm.polishFailedMemos[memo])
        XCTAssertFalse(mockAIClient.polishCalled)
    }

    func testPolish_WhenContentEmpty_DoesNothing() {
        mockConfig.isServerSet = true
        let vm = makeVM()
        let memo = makeMemo(content: "")

        vm.polish(memo)

        XCTAssertFalse(mockAIClient.polishCalled)
    }

    func testPolish_OnSuccess_SavesPolishedContent() async throws {
        mockConfig.isServerSet = true
        mockAIClient.polishResult = ["Polished ", "text"]
        let vm = makeVM()
        let memo = makeMemo(content: "raw text")

        vm.polish(memo)

        // Wait for async task to complete
        try await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertTrue(mockAIClient.polishCalled)
        XCTAssertEqual(mockAIClient.lastPolishText, "raw text")
        XCTAssertEqual(memo.polishedContent, "Polished text")
        XCTAssertFalse(vm.polishingMemos.contains(memo))
    }

    func testPolish_OnFailure_RecordsError() async throws {
        mockConfig.isServerSet = true
        mockAIClient.polishError = URLError(.badServerResponse)
        let vm = makeVM()
        let memo = makeMemo(content: "raw text")

        vm.polish(memo)

        try await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertNotNil(vm.polishFailedMemos[memo])
        XCTAssertNil(memo.polishedContent)
        XCTAssertFalse(vm.polishingMemos.contains(memo))
    }

    // MARK: - deletePolish()

    func testDeletePolish_ClearsPolishedContent() throws {
        let vm = makeVM()
        let memo = makeMemo(content: "raw text")
        memo.polishedContent = "polished"
        try container.context.save()

        vm.deletePolish(memo)

        XCTAssertNil(memo.polishedContent)
    }

    // MARK: - generateTitle()

    func testGenerateTitle_WhenServerNotSet_RecordsError() {
        mockConfig.isServerSet = false
        let vm = makeVM()
        let memo = makeMemo(content: "some text")

        vm.generateTitle(memo)

        XCTAssertNotNil(vm.titleFailedMemos[memo])
        XCTAssertFalse(mockAIClient.generateTitleCalled)
    }

    func testGenerateTitle_WhenServerNotSet_Silent_NoError() {
        mockConfig.isServerSet = false
        let vm = makeVM()
        let memo = makeMemo(content: "some text")

        vm.generateTitle(memo, silent: true)

        XCTAssertNil(vm.titleFailedMemos[memo])
        XCTAssertFalse(mockAIClient.generateTitleCalled)
    }

    func testGenerateTitle_WhenContentEmpty_DoesNothing() {
        mockConfig.isServerSet = true
        let vm = makeVM()
        let memo = makeMemo(content: "")

        vm.generateTitle(memo)

        XCTAssertFalse(mockAIClient.generateTitleCalled)
    }

    func testGenerateTitle_OnSuccess_SavesTitle() async throws {
        mockConfig.isServerSet = true
        mockAIClient.generateTitleResult = "My Title"
        let vm = makeVM()
        let memo = makeMemo(content: "some text about my day")

        vm.generateTitle(memo)

        try await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertTrue(mockAIClient.generateTitleCalled)
        XCTAssertEqual(memo.title, "My Title")
        XCTAssertFalse(vm.titleGeneratingMemos.contains(memo))
    }

    func testGenerateTitle_OnFailure_RecordsError() async throws {
        mockConfig.isServerSet = true
        mockAIClient.generateTitleError = URLError(.badServerResponse)
        let vm = makeVM()
        let memo = makeMemo(content: "some text")

        vm.generateTitle(memo)

        try await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertNotNil(vm.titleFailedMemos[memo])
        XCTAssertNil(memo.title)
        XCTAssertFalse(vm.titleGeneratingMemos.contains(memo))
    }

    func testGenerateTitle_OnFailure_Silent_NoErrorRecorded() async throws {
        mockConfig.isServerSet = true
        mockAIClient.generateTitleError = URLError(.badServerResponse)
        let vm = makeVM()
        let memo = makeMemo(content: "some text")

        vm.generateTitle(memo, silent: true)

        try await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertNil(vm.titleFailedMemos[memo])
        XCTAssertNil(memo.title)
    }

    // MARK: - deleteTitle()

    func testDeleteTitle_ClearsTitle() throws {
        let vm = makeVM()
        let memo = makeMemo(content: "some text")
        memo.title = "Old Title"
        try container.context.save()

        vm.deleteTitle(memo)

        XCTAssertNil(memo.title)
    }

    // MARK: - Auto title generation after transcribe

    func testTranscribe_OnSuccess_TriggersAutoTitleWhenServerSet() async throws {
        mockConfig.isServerSet = true
        mockTranscription.transcribeMemoResult = .success("Transcribed text")
        mockAIClient.generateTitleResult = "Auto Title"
        let vm = makeVM()
        let memo = makeMemo(file: "test.m4a", content: "")

        vm.transcribe(memo)

        try await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertTrue(mockAIClient.generateTitleCalled)
        XCTAssertEqual(memo.title, "Auto Title")
    }

    func testTranscribe_OnSuccess_SkipsTitleWhenAlreadyHasTitle() {
        mockConfig.isServerSet = true
        mockTranscription.transcribeMemoResult = .success("Transcribed text")
        let vm = makeVM()
        let memo = makeMemo(file: "test.m4a", content: "")
        memo.title = "Existing"

        vm.transcribe(memo)

        XCTAssertFalse(mockAIClient.generateTitleCalled)
    }

    func testTranscribe_OnSuccess_SkipsTitleWhenServerNotSet() {
        mockConfig.isServerSet = false
        mockTranscription.transcribeMemoResult = .success("Transcribed text")
        let vm = makeVM()
        let memo = makeMemo(file: "test.m4a", content: "")

        vm.transcribe(memo)

        XCTAssertFalse(mockAIClient.generateTitleCalled)
    }

    // MARK: - Auto title generation after polish

    func testPolish_OnSuccess_TriggersAutoTitle() async throws {
        mockConfig.isServerSet = true
        mockAIClient.polishResult = ["Polished ", "text"]
        mockAIClient.generateTitleResult = "Polish Title"
        let vm = makeVM()
        let memo = makeMemo(content: "raw text")

        vm.polish(memo)

        try await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertTrue(mockAIClient.generateTitleCalled)
        XCTAssertEqual(memo.title, "Polish Title")
    }

    // MARK: - MemoEntity title properties

    func testMemoEntity_HasTitle_WhenSet() {
        let memo = makeMemo(content: "raw")
        memo.title = "Title"

        XCTAssertTrue(memo.hasTitle)
        XCTAssertEqual(memo.viewTitle, "Title")
    }

    func testMemoEntity_HasTitle_FalseWhenNil() {
        let memo = makeMemo(content: "raw")

        XCTAssertFalse(memo.hasTitle)
        XCTAssertEqual(memo.viewTitle, "")
    }

    func testMemoEntity_HasTitle_FalseWhenEmpty() {
        let memo = makeMemo(content: "raw")
        memo.title = ""

        XCTAssertFalse(memo.hasTitle)
    }

    // MARK: - MemoEntity search matching

    func testMatchesSearch_MatchesContent() {
        let memo = makeMemo(content: "Hello World")

        XCTAssertTrue(memo.matchesSearch("hello"))
        XCTAssertTrue(memo.matchesSearch("WORLD"))
    }

    func testMatchesSearch_MatchesTitle() {
        let memo = makeMemo(content: "body")
        memo.title = "Meeting Notes"

        XCTAssertTrue(memo.matchesSearch("meeting"))
    }

    func testMatchesSearch_MatchesPolishedContent() {
        let memo = makeMemo(content: "raw")
        memo.polishedContent = "Polished diary entry"

        XCTAssertTrue(memo.matchesSearch("diary"))
    }

    func testMatchesSearch_ExcludesHiddenMemos() {
        let memo = makeMemo(content: "Hello World")
        memo.isHidden = true

        XCTAssertFalse(memo.matchesSearch("hello"))
    }

    func testMatchesSearch_ReturnsFalseWhenNoMatch() {
        let memo = makeMemo(content: "Hello World")

        XCTAssertFalse(memo.matchesSearch("xyz"))
    }

    func testMatchesSearch_CaseInsensitive() {
        let memo = makeMemo(content: "café latte")

        XCTAssertTrue(memo.matchesSearch("CAFÉ"))
        XCTAssertTrue(memo.matchesSearch("cafe"))
    }

    // MARK: - MemoEntity polished properties

    func testMemoEntity_HasPolishedContent_WhenSet() {
        let memo = makeMemo(content: "raw")
        memo.polishedContent = "polished"

        XCTAssertTrue(memo.hasPolishedContent)
        XCTAssertEqual(memo.displayContent, "polished")
    }

    func testMemoEntity_DisplayContent_FallsBackToContent() {
        let memo = makeMemo(content: "raw")

        XCTAssertFalse(memo.hasPolishedContent)
        XCTAssertEqual(memo.displayContent, "raw")
    }
}
