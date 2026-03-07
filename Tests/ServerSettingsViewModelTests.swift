import XCTest
@testable import Murmurs

final class ServerSettingsViewModelTests: XCTestCase {

    // MARK: - Combine 管道

    func testIsServerValid_WhenHostNotEmpty_AndNoKeyRequired() {
        let vm = ServerSettingsViewModel()
        vm.host = "https://api.example.com/"
        vm.requiresKey = false
        XCTAssertTrue(vm.isServerValid)
    }

    func testIsServerValid_WhenHostEmpty() {
        let vm = ServerSettingsViewModel()
        vm.host = ""
        vm.requiresKey = false
        XCTAssertFalse(vm.isServerValid)
    }

    func testIsServerValid_WhenRequiresKey_AndKeyEmpty() {
        let vm = ServerSettingsViewModel()
        vm.host = "https://api.example.com/"
        vm.requiresKey = true
        vm.key = ""
        XCTAssertFalse(vm.isServerValid)
    }

    func testIsServerValid_WhenRequiresKey_AndKeyProvided() {
        let vm = ServerSettingsViewModel()
        vm.host = "https://api.example.com/"
        vm.requiresKey = true
        vm.key = "sk-abc123"
        XCTAssertTrue(vm.isServerValid)
    }

    func testRequiresKey_WhenSetToFalse_ClearsKey() {
        let vm = ServerSettingsViewModel()
        vm.requiresKey = true
        vm.key = "sk-abc123"
        vm.requiresKey = false
        XCTAssertEqual(vm.key, "")
    }

    func testHostChange_ResetsIsVerified() {
        let vm = ServerSettingsViewModel()
        vm.host = "https://api.example.com/"
        XCTAssertFalse(vm.isVerified)
    }

    // MARK: - verify()

    func testVerify_Success_SetsItemsToSuccess() async {
        let mockClient = MockAIClient()
        let vm = ServerSettingsViewModel(aiClient: mockClient)
        vm.host = "https://api.example.com/"

        vm.verify()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertTrue(mockClient.verifyCalled)
        XCTAssertTrue(mockClient.verifyWhisperCalled)
        XCTAssertTrue(vm.isVerified)
        XCTAssertEqual(vm.verificationItems[.gpt_4o], .success)
        XCTAssertEqual(vm.verificationItems[.whisper], .success)
    }

    func testVerify_GPTFails_WhisperSucceeds() async {
        let mockClient = MockAIClient()
        mockClient.verifyError = URLError(.badServerResponse)
        let vm = ServerSettingsViewModel(aiClient: mockClient)
        vm.host = "https://api.example.com/"

        vm.verify()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertTrue(vm.isVerified)
        if case .failure = vm.verificationItems[.gpt_4o] {
        } else {
            XCTFail("Expected gpt_4o to fail")
        }
        XCTAssertEqual(vm.verificationItems[.whisper], .success)
    }

    func testVerify_AllFail_IsVerifiedFalse() async {
        let mockClient = MockAIClient()
        mockClient.verifyError = URLError(.badServerResponse)
        mockClient.verifyWhisperError = URLError(.badServerResponse)
        let vm = ServerSettingsViewModel(aiClient: mockClient)
        vm.host = "https://api.example.com/"

        vm.verify()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertFalse(vm.isVerified)
    }

    func testVerify_PassesKeyWhenRequired() async {
        let mockClient = MockAIClient()
        let vm = ServerSettingsViewModel(aiClient: mockClient)
        vm.host = "https://api.example.com/"
        vm.requiresKey = true
        vm.key = "sk-test123"

        vm.verify()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(mockClient.lastVerifyKey, "sk-test123")
    }

    func testVerify_DoesNotPassKey_WhenNotRequired() async {
        let mockClient = MockAIClient()
        let vm = ServerSettingsViewModel(aiClient: mockClient)
        vm.host = "https://api.example.com/"
        vm.requiresKey = false

        vm.verify()
        await Task.yield()
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertNil(mockClient.lastVerifyKey)
    }

    // MARK: - save() / load()

    func testSave_WritesToConfig() {
        let config = MockConfig()
        let vm = ServerSettingsViewModel(config: config)
        vm.host = "https://custom.api.com/"
        vm.requiresKey = true
        vm.key = "sk-mykey"
        vm.save()

        XCTAssertEqual(config.serverHost, "https://custom.api.com/")
        XCTAssertEqual(config.serverAPIKey, "sk-mykey")
    }

    func testLoad_ReadsFromConfig() {
        let config = MockConfig()
        config.serverHost = "https://loaded.api.com/"
        config.serverAPIKey = "sk-loaded"
        let vm = ServerSettingsViewModel(config: config)
        vm.load()

        XCTAssertEqual(vm.host, "https://loaded.api.com/")
        XCTAssertTrue(vm.requiresKey)
        XCTAssertEqual(vm.key, "sk-loaded")
    }
}
