import XCTest
@testable import Murmurs

@MainActor
final class AccountServiceTests: XCTestCase {
    private let storedCode = "11111-22222-33333-44444-55555"

    // MARK: - ensureAccount

    func testFirstLaunchCreatesAccountAndStoresCredentials() async {
        let api = MockAccountAPI()
        let store = MockCredentialStore()
        let service = AccountService(api: api, store: store)

        await service.ensureAccount()

        XCTAssertEqual(service.state, .ready(userId: "user-new"))
        XCTAssertEqual(store.token, "token-new")
        XCTAssertEqual(store.userId, "user-new")
        XCTAssertEqual(store.recoveryCode, "AAAAA-BBBBB-CCCCC-DDDDD-EEEEE")
        XCTAssertEqual(api.createCalls, 1)
    }

    func testSyncedRecoveryCodeRestoresInsteadOfCreating() async {
        let api = MockAccountAPI()
        let store = MockCredentialStore(recoveryCode: storedCode)
        let service = AccountService(api: api, store: store)

        await service.ensureAccount()

        XCTAssertEqual(service.state, .ready(userId: "user-recovered"))
        XCTAssertEqual(api.recoveredCodes, [storedCode])
        XCTAssertEqual(api.createCalls, 0)
        XCTAssertEqual(store.token, "token-recovered")
        XCTAssertEqual(store.recoveryCode, storedCode)
    }

    func testExistingCredentialsNeedNoNetwork() async {
        let api = MockAccountAPI()
        let store = MockCredentialStore(token: "t", userId: "u", recoveryCode: storedCode)
        let service = AccountService(api: api, store: store)

        XCTAssertEqual(service.state, .ready(userId: "u"))
        await service.ensureAccount()

        XCTAssertEqual(api.createCalls, 0)
        XCTAssertTrue(api.recoveredCodes.isEmpty)
    }

    func testOfflineLeavesNoAccountAndRetriesLater() async {
        let api = MockAccountAPI()
        api.createResult = .failure(.network)
        let store = MockCredentialStore()
        let service = AccountService(api: api, store: store)

        await service.ensureAccount()
        XCTAssertEqual(service.state, .none)
        XCTAssertNil(store.token)

        api.createResult = .success(AccountCredentials(userId: "u2", token: "t2", recoveryCode: storedCode))
        await service.ensureAccount()
        XCTAssertEqual(service.state, .ready(userId: "u2"))
        XCTAssertEqual(api.createCalls, 2)
    }

    func testInvalidSyncedCodeNeedsRestoreWithoutCreatingAccount() async {
        let api = MockAccountAPI()
        api.recoverResult = .failure(.invalidRecoveryCode)
        let store = MockCredentialStore(recoveryCode: storedCode)
        let service = AccountService(api: api, store: store)

        await service.ensureAccount()

        XCTAssertEqual(service.state, .needsRestore)
        XCTAssertEqual(api.createCalls, 0)
        XCTAssertEqual(store.recoveryCode, storedCode)
    }

    // MARK: - Unauthorized

    func testUnauthorizedRecoversOnceWithStoredCode() async {
        let api = MockAccountAPI()
        let store = MockCredentialStore(token: "expired", userId: "u", recoveryCode: storedCode)
        let service = AccountService(api: api, store: store)

        let refreshed = await service.refreshAfterUnauthorized()

        XCTAssertTrue(refreshed)
        XCTAssertEqual(api.recoveredCodes, [storedCode])
        XCTAssertEqual(store.token, "token-recovered")
        XCTAssertEqual(service.state, .ready(userId: "user-recovered"))
    }

    func testUnauthorizedWithRejectedCodeNeedsRestoreAndKeepsCode() async {
        let api = MockAccountAPI()
        api.recoverResult = .failure(.invalidRecoveryCode)
        let store = MockCredentialStore(token: "expired", userId: "u", recoveryCode: storedCode)
        let service = AccountService(api: api, store: store)

        let refreshed = await service.refreshAfterUnauthorized()

        XCTAssertFalse(refreshed)
        XCTAssertEqual(service.state, .needsRestore)
        XCTAssertNil(store.token)
        XCTAssertEqual(store.recoveryCode, storedCode)

        await service.ensureAccount()
        XCTAssertEqual(api.createCalls, 0, "must not silently create a different account")
    }

    func testRotateRetriesOnceAfterUnauthorized() async throws {
        let api = MockAccountAPI()
        api.rotateResults = [.failure(.unauthorized), .success("NEWCO-DEAAA-AAAAA-AAAAA-AAAAA")]
        let store = MockCredentialStore(token: "expired", userId: "u", recoveryCode: storedCode)
        let service = AccountService(api: api, store: store)

        let code = try await service.rotateRecoveryCode()

        XCTAssertEqual(code, "NEWCO-DEAAA-AAAAA-AAAAA-AAAAA")
        XCTAssertEqual(api.rotateTokens, ["expired", "token-recovered"])
        XCTAssertEqual(store.recoveryCode, code)
    }

    // MARK: - Restore, delete

    func testRestoreSwitchesAccountAndNormalizesCode() async throws {
        let api = MockAccountAPI()
        let store = MockCredentialStore(token: "t", userId: "u", recoveryCode: storedCode)
        let service = AccountService(api: api, store: store)

        try await service.restore(code: "abcde fghjk mnpqr stvwx yz012")

        XCTAssertEqual(api.recoveredCodes, ["ABCDE-FGHJK-MNPQR-STVWX-YZ012"])
        XCTAssertEqual(store.recoveryCode, "ABCDE-FGHJK-MNPQR-STVWX-YZ012")
        XCTAssertEqual(service.state, .ready(userId: "user-recovered"))
    }

    func testRestoreWithRejectedCodeKeepsCurrentAccount() async {
        let api = MockAccountAPI()
        api.recoverResult = .failure(.invalidRecoveryCode)
        let store = MockCredentialStore(token: "t", userId: "u", recoveryCode: storedCode)
        let service = AccountService(api: api, store: store)

        do {
            try await service.restore(code: "ABCDE-FGHJK-MNPQR-STVWX-YZ012")
            XCTFail("expected an error")
        } catch {
            XCTAssertEqual(error as? AccountAPIError, .invalidRecoveryCode)
        }
        XCTAssertEqual(service.state, .ready(userId: "u"))
        XCTAssertEqual(store.token, "t")
        XCTAssertEqual(store.recoveryCode, storedCode)
    }

    func testRestoreRejectsMalformedInputWithoutNetwork() async {
        let api = MockAccountAPI()
        let service = AccountService(api: api, store: MockCredentialStore())

        do {
            try await service.restore(code: "not a code")
            XCTFail("expected an error")
        } catch {
            XCTAssertEqual(error as? AccountAPIError, .invalidRecoveryCode)
        }
        XCTAssertTrue(api.recoveredCodes.isEmpty)
    }

    func testDeleteClearsCredentials() async throws {
        let api = MockAccountAPI()
        let store = MockCredentialStore(token: "t", userId: "u", recoveryCode: storedCode)
        let service = AccountService(api: api, store: store)

        try await service.deleteAccount()

        XCTAssertEqual(api.deletedTokens, ["t"])
        XCTAssertNil(store.token)
        XCTAssertNil(store.userId)
        XCTAssertNil(store.recoveryCode)
        XCTAssertEqual(service.state, .none)
    }

    // MARK: - Environment

    func testAutomaticSetupIsDisabledDuringUnitTests() {
        XCTAssertFalse(AccountService.isAutomaticSetupEnabled)
    }

    func testRecoveryCodeFormat() {
        XCTAssertEqual(RecoveryCodeFormat.normalized("oiL00 11111-22222 33333-44444"), "01100-11111-22222-33333-44444")
        XCTAssertNil(RecoveryCodeFormat.normalized("UUUUU-UUUUU-UUUUU-UUUUU-UUUUU"))
        XCTAssertNil(RecoveryCodeFormat.normalized("ABCDE"))
    }
}
