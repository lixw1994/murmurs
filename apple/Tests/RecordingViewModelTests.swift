import XCTest
@testable import Murmurs

@MainActor
final class RecordingViewModelTests: XCTestCase {
    var config: MockConfig!

    override func setUp() {
        config = MockConfig()
    }

    // MARK: - shouldUseLiveTranscription

    func testShouldUseLiveTranscription_AppleProviderEnabled() {
        config.transEnabled = true
        config.transProvider = .apple
        let vm = RecordingViewModel(config: config)

        XCTAssertTrue(vm.shouldUseLiveTranscription)
    }

    func testShouldUseLiveTranscription_OpenAIProvider() {
        config.transEnabled = true
        config.transProvider = .openai
        let vm = RecordingViewModel(config: config)

        XCTAssertFalse(vm.shouldUseLiveTranscription)
    }

    func testShouldUseLiveTranscription_TransDisabled() {
        config.transEnabled = false
        config.transProvider = .apple
        let vm = RecordingViewModel(config: config)

        XCTAssertFalse(vm.shouldUseLiveTranscription)
    }

    func testShouldUseLiveTranscription_TransDisabledOpenAI() {
        config.transEnabled = false
        config.transProvider = .openai
        let vm = RecordingViewModel(config: config)

        XCTAssertFalse(vm.shouldUseLiveTranscription)
    }
}
