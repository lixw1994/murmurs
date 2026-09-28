import Foundation
import KeychainAccess

/// Where the account credentials live (adr/0015).
protocol CredentialStore: AnyObject {
    var token: String? { get set }
    var userId: String? { get set }
    /// Synchronized through iCloud Keychain so a new device can restore the account.
    var recoveryCode: String? { get set }
}

extension CredentialStore {
    func clear() {
        token = nil
        userId = nil
        recoveryCode = nil
    }
}

/// Keychain-backed store: the session token and user id stay on this device;
/// the recovery code is synchronizable.
final class KeychainCredentialStore: CredentialStore {
    private static let service = "com.tangyue.murmurs.account"

    private let deviceOnly = Keychain(service: service)
        .synchronizable(false)
        .accessibility(.afterFirstUnlockThisDeviceOnly)
    private let synced = Keychain(service: service)
        .synchronizable(true)
        .accessibility(.afterFirstUnlock)

    var token: String? {
        get { try? deviceOnly.get("session-token") }
        set { write(newValue, key: "session-token", in: deviceOnly) }
    }

    var userId: String? {
        get { try? deviceOnly.get("user-id") }
        set { write(newValue, key: "user-id", in: deviceOnly) }
    }

    var recoveryCode: String? {
        get { try? synced.get("recovery-code") }
        set { write(newValue, key: "recovery-code", in: synced) }
    }

    private func write(_ value: String?, key: String, in keychain: Keychain) {
        if let value {
            try? keychain.set(value, key: key)
        } else {
            try? keychain.remove(key)
        }
    }
}
