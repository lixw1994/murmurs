import XCTest
@testable import Murmurs

@MainActor
final class AccountViewModelTests: XCTestCase {
    private let code = "11111-22222-33333-44444-55555"

    private func makeVM(api: MockAccountAPI = MockAccountAPI(), copied: ((String) -> Void)? = nil) -> (AccountViewModel, MockCredentialStore) {
        let store = MockCredentialStore(token: "t", userId: "u", recoveryCode: code)
        let service = AccountService(api: api, store: store)
        return (AccountViewModel(service: service, copyToPasteboard: copied ?? { _ in }), store)
    }

    func testCopyPutsFormattedCodeOnPasteboard() {
        var pasted: String?
        let (vm, _) = makeVM(copied: { pasted = $0 })
        vm.copyCode()
        XCTAssertEqual(pasted, code)
        XCTAssertTrue(vm.didCopy)
    }

    func testRestoreOnlyEnabledForWellFormedCodes() {
        let (vm, _) = makeVM()
        vm.restoreInput = "abc"
        XCTAssertFalse(vm.canRestore)
        vm.restoreInput = "abcde fghjk mnpqr stvwx yz012"
        XCTAssertTrue(vm.canRestore)
    }

    func testInvalidRestoreShowsErrorAndKeepsAccount() async {
        let api = MockAccountAPI()
        api.recoverResult = .failure(.invalidRecoveryCode)
        let (vm, store) = makeVM(api: api)
        vm.restoreInput = "ABCDE-FGHJK-MNPQR-STVWX-YZ012"

        await vm.restore()

        XCTAssertEqual(vm.errorMessage, L(.account_error_invalid_code))
        XCTAssertEqual(store.token, "t")
        XCTAssertEqual(vm.state, .ready(userId: "u"))
    }

    func testDeleteClearsAccount() async {
        let (vm, store) = makeVM()
        await vm.deleteAccount()
        XCTAssertNil(vm.errorMessage)
        XCTAssertNil(store.recoveryCode)
        XCTAssertEqual(vm.state, .none)
    }

    func testNetworkErrorMessage() async {
        let api = MockAccountAPI()
        api.rotateResults = [.failure(.network)]
        let (vm, _) = makeVM(api: api)
        await vm.rotateCode()
        XCTAssertEqual(vm.errorMessage, L(.account_error_network))
    }
}
