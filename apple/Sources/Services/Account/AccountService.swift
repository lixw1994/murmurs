import Foundation
import Observation
import XLog

/// Creates, restores, and manages the anonymous account (adr/0015).
///
/// - First launch: restores with a recovery code from iCloud Keychain if one
///   exists, otherwise creates a new account. No UI is shown.
/// - Offline: stays `.none` and retries on the next `ensureAccount()`.
/// - A rejected session is recovered once with the stored code; if that fails
///   the state becomes `.needsRestore` and no different account is created.
@MainActor
@Observable
final class AccountService {
    enum State: Equatable {
        case none
        case working
        case ready(userId: String)
        case needsRestore
    }

    static let shared = AccountService(
        api: LiveAccountAPI(serverURL: LiveAccountAPI.configuredServerURL ?? URL(string: "https://murmurs.denkit.app")!),
        store: KeychainCredentialStore()
    )

    /// Account bootstrap is off for snapshot builds and unit-test runs.
    static var isAutomaticSetupEnabled: Bool {
        #if SNAPSHOT
        return false
        #else
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil
        #endif
    }

    private(set) var state: State = .none
    private let api: AccountAPI
    private let store: CredentialStore

    init(api: AccountAPI, store: CredentialStore) {
        self.api = api
        self.store = store
        if let userId = store.userId, store.token != nil {
            state = .ready(userId: userId)
        }
    }

    var recoveryCode: String? { store.recoveryCode }

    /// Makes sure an account exists. Safe to call repeatedly.
    func ensureAccount() async {
        if state == .working || state == .needsRestore { return }
        if store.token != nil, let userId = store.userId {
            state = .ready(userId: userId)
            return
        }

        state = .working
        do {
            if let code = store.recoveryCode {
                let credentials = try await api.recover(code: code)
                save(credentials, recoveryCode: code)
            } else {
                let credentials = try await api.createAccount()
                save(credentials, recoveryCode: credentials.recoveryCode)
            }
        } catch AccountAPIError.invalidRecoveryCode {
            store.token = nil
            store.userId = nil
            state = .needsRestore
        } catch {
            XLog.error("Account setup failed: \(error)", source: "Account")
            state = .none
        }
    }

    /// Call when the API rejected the stored session token. Returns whether a
    /// new session was obtained.
    @discardableResult
    func refreshAfterUnauthorized() async -> Bool {
        store.token = nil
        store.userId = nil
        guard let code = store.recoveryCode else {
            state = .none
            return false
        }
        state = .working
        do {
            let credentials = try await api.recover(code: code)
            save(credentials, recoveryCode: code)
            return true
        } catch AccountAPIError.invalidRecoveryCode {
            state = .needsRestore
            return false
        } catch {
            state = .none
            return false
        }
    }

    /// Switches this device to the account that owns `code`. The current
    /// account is kept if the code is rejected.
    func restore(code input: String) async throws {
        guard let code = RecoveryCodeFormat.normalized(input) else {
            throw AccountAPIError.invalidRecoveryCode
        }
        let credentials = try await api.recover(code: code)
        save(credentials, recoveryCode: code)
    }

    /// Replaces the recovery code; the previous one stops working.
    func rotateRecoveryCode() async throws -> String {
        let code = try await authorized { try await self.api.rotateRecoveryCode(token: $0) }
        store.recoveryCode = code
        return code
    }

    /// Deletes the account on the server and forgets its credentials. Local
    /// memos are not touched.
    func deleteAccount() async throws {
        try await authorized { try await self.api.deleteAccount(token: $0) }
        store.clear()
        state = .none
    }

    private func save(_ credentials: AccountCredentials, recoveryCode: String?) {
        store.token = credentials.token
        store.userId = credentials.userId
        if let recoveryCode {
            store.recoveryCode = recoveryCode
        }
        state = .ready(userId: credentials.userId)
    }

    /// Runs `operation` with the session token, recovering once if it is rejected.
    private func authorized<T>(_ operation: @escaping (String) async throws -> T) async throws -> T {
        guard let token = store.token else { throw AccountAPIError.unauthorized }
        do {
            return try await operation(token)
        } catch AccountAPIError.unauthorized {
            guard await refreshAfterUnauthorized(), let token = store.token else {
                throw AccountAPIError.unauthorized
            }
            return try await operation(token)
        }
    }
}
