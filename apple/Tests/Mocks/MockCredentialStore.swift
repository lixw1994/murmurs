@testable import Murmurs

final class MockCredentialStore: CredentialStore {
    var token: String?
    var userId: String?
    var recoveryCode: String?

    init(token: String? = nil, userId: String? = nil, recoveryCode: String? = nil) {
        self.token = token
        self.userId = userId
        self.recoveryCode = recoveryCode
    }
}
