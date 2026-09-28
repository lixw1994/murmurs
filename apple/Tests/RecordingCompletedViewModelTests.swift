import XCTest
import SwiftData
@testable import Murmurs

@MainActor
final class RecordingCompletedViewModelTests: XCTestCase {
    var container: DataContainer!
    var mockTranscription: MockTranscriptionService!
    var config: MockConfig!

    override func setUp() {
        container = DataContainer(inMemory: true)
        mockTranscription = MockTranscriptionService()
        config = MockConfig()
    }

    func testTranscribe_WhenTransEnabled_CallsService() async {
        config.transEnabled = true
        let url = URL(fileURLWithPath: "/tmp/test.m4a")
        let vm = RecordingCompletedViewModel(
            voicePath: url, context: container.context, config: config,
            transcription: mockTranscription
        )

        vm.transcribe()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertTrue(mockTranscription.transcribeAsyncCalled)
    }

    func testTranscribe_WhenTransDisabled_DoesNotCallService() async {
        config.transEnabled = false
        let url = URL(fileURLWithPath: "/tmp/test.m4a")
        let vm = RecordingCompletedViewModel(
            voicePath: url, context: container.context, config: config,
            transcription: mockTranscription
        )

        vm.transcribe()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertFalse(mockTranscription.transcribeAsyncCalled)
    }

    func testTranscribe_OnSuccess_SetsTranscribedText() async {
        config.transEnabled = true
        mockTranscription.transcribeAsyncResult = .success("Hello world")
        let url = URL(fileURLWithPath: "/tmp/test.m4a")
        let vm = RecordingCompletedViewModel(
            voicePath: url, context: container.context, config: config,
            transcription: mockTranscription
        )

        vm.transcribe()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(vm.transcribedText, "Hello world")
        XCTAssertTrue(vm.hasTranscribed)
        XCTAssertFalse(vm.isTranscribing)
    }

    func testTranscribe_OnFailure_SetsError() async {
        config.transEnabled = true
        mockTranscription.transcribeAsyncResult = .failure(URLError(.badServerResponse))
        let url = URL(fileURLWithPath: "/tmp/test.m4a")
        let vm = RecordingCompletedViewModel(
            voicePath: url, context: container.context, config: config,
            transcription: mockTranscription
        )

        vm.transcribe()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertNotNil(vm.transcriptionError)
        XCTAssertFalse(vm.isTranscribing)
    }

    // MARK: - save()

    func testSave_CreatesMemoEntityWithCorrectAttributes() throws {
        let url = URL(fileURLWithPath: "/tmp/test-recording.m4a")
        let vm = RecordingCompletedViewModel(
            voicePath: url, context: container.context, config: config,
            transcription: mockTranscription
        )
        vm.content = "Test content"
        vm.duration = 15.5

        let descriptor = FetchDescriptor<MemoEntity>()
        let initialCount = try container.context.fetch(descriptor).count

        vm.save()

        let results = try container.context.fetch(descriptor)
        XCTAssertEqual(results.count, initialCount + 1)
        let saved = results.first { $0.content == "Test content" }
        XCTAssertNotNil(saved)
        XCTAssertEqual(saved?.file, "test-recording.m4a")
        XCTAssertEqual(saved?.duration, 15.5)
    }

    func testSave_SetsTranscribedFlag_WhenHasTranscribed() throws {
        let url = URL(fileURLWithPath: "/tmp/test.m4a")
        let vm = RecordingCompletedViewModel(
            voicePath: url, context: container.context, config: config,
            transcription: mockTranscription
        )
        vm.content = "Transcribed"
        vm.hasTranscribed = true

        vm.save()

        let descriptor = FetchDescriptor<MemoEntity>()
        let saved = try container.context.fetch(descriptor).first { $0.content == "Transcribed" }
        XCTAssertTrue(saved?.transcribed ?? false)
    }

    func testSave_SetsSavedFlag_FalseWhenMoveFileFails() throws {
        let url = URL(fileURLWithPath: "/tmp/test.m4a")
        let vm = RecordingCompletedViewModel(
            voicePath: url, context: container.context, config: config,
            transcription: mockTranscription
        )
        vm.content = "test"

        XCTAssertFalse(vm.saved)
        vm.save()
        XCTAssertFalse(vm.saved)
    }

    // MARK: - delete()

    func testDelete_WhenFileNotExist_DoesNotCrash() {
        let url = URL(fileURLWithPath: "/tmp/nonexistent-\(UUID().uuidString).m4a")
        let vm = RecordingCompletedViewModel(
            voicePath: url, context: container.context, config: config,
            transcription: mockTranscription
        )

        vm.delete()
    }

    // MARK: - Pre-transcribed text

    func testInit_WithPreTranscribedText_SetsContentAndHasTranscribed() {
        let url = URL(fileURLWithPath: "/tmp/test.m4a")
        let vm = RecordingCompletedViewModel(
            voicePath: url, preTranscribedText: "Pre-transcribed content",
            context: container.context, config: config,
            transcription: mockTranscription
        )

        XCTAssertEqual(vm.content, "Pre-transcribed content")
        XCTAssertTrue(vm.hasTranscribed)
        XCTAssertEqual(vm.transcribedText, "Pre-transcribed content")
    }

    func testTranscribe_WithPreTranscribedText_SkipsTranscriptionCall() async {
        config.transEnabled = true
        let url = URL(fileURLWithPath: "/tmp/test.m4a")
        let vm = RecordingCompletedViewModel(
            voicePath: url, preTranscribedText: "Already transcribed",
            context: container.context, config: config,
            transcription: mockTranscription
        )

        vm.transcribe()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertFalse(mockTranscription.transcribeAsyncCalled)
        XCTAssertEqual(vm.content, "Already transcribed")
    }

    func testInit_WithoutPreTranscribedText_DoesNotSetContent() {
        let url = URL(fileURLWithPath: "/tmp/test.m4a")
        let vm = RecordingCompletedViewModel(
            voicePath: url, context: container.context, config: config,
            transcription: mockTranscription
        )

        XCTAssertEqual(vm.content, "")
        XCTAssertFalse(vm.hasTranscribed)
        XCTAssertNil(vm.transcribedText)
    }

    // MARK: - transcribe() reentrancy guard

    func testTranscribe_WhenAlreadyTranscribing_DoesNotCallServiceAgain() async {
        config.transEnabled = true
        let url = URL(fileURLWithPath: "/tmp/test.m4a")
        let vm = RecordingCompletedViewModel(
            voicePath: url, context: container.context, config: config,
            transcription: mockTranscription
        )
        vm.isTranscribing = true

        vm.transcribe()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertFalse(mockTranscription.transcribeAsyncCalled)
    }
}
