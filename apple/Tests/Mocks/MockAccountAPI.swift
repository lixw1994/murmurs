import Foundation
@testable import Murmurs

final class MockAccountAPI: AccountAPI {
    var createResult: Result<AccountCredentials, AccountAPIError> =
        .success(AccountCredentials(userId: "user-new", token: "token-new", recoveryCode: "AAAAA-BBBBB-CCCCC-DDDDD-EEEEE"))
    var recoverResult: Result<AccountCredentials, AccountAPIError> =
        .success(AccountCredentials(userId: "user-recovered", token: "token-recovered", recoveryCode: nil))
    var rotateResults: [Result<String, AccountAPIError>] = [.success("FFFFF-GGGGG-HHHHH-JJJJJ-KKKKK")]
    var deleteResult: Result<Void, AccountAPIError> = .success(())

    private(set) var createCalls = 0
    private(set) var recoveredCodes: [String] = []
    private(set) var rotateTokens: [String] = []
    private(set) var deletedTokens: [String] = []

    func createAccount() async throws -> AccountCredentials {
        createCalls += 1
        return try createResult.get()
    }

    func recover(code: String) async throws -> AccountCredentials {
        recoveredCodes.append(code)
        return try recoverResult.get()
    }

    func rotateRecoveryCode(token: String) async throws -> String {
        rotateTokens.append(token)
        return try (rotateResults.count > 1 ? rotateResults.removeFirst() : rotateResults[0]).get()
    }

    func signOut(token: String) async throws {}

    func deleteAccount(token: String) async throws {
        deletedTokens.append(token)
        try deleteResult.get()
    }
}
