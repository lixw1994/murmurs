import Foundation
import MurmursAPI

struct AccountCredentials: Equatable {
    let userId: String
    let token: String
    /// Only present when the account was just created.
    let recoveryCode: String?
}

enum AccountAPIError: Error, Equatable {
    case unauthorized
    case invalidRecoveryCode
    case rateLimited
    case network
    case server(statusCode: Int)
}

/// The account endpoints of /api/v1 (adr/0015).
protocol AccountAPI {
    func createAccount() async throws -> AccountCredentials
    func recover(code: String) async throws -> AccountCredentials
    func rotateRecoveryCode(token: String) async throws -> String
    func signOut(token: String) async throws
    func deleteAccount(token: String) async throws
}

/// `AccountAPI` backed by the client generated from contract/openapi.json.
struct LiveAccountAPI: AccountAPI {
    let serverURL: URL

    /// The API base URL for this build configuration (Info.plist `MurmursAPIBaseURL`).
    static var configuredServerURL: URL? {
        (Bundle.main.object(forInfoDictionaryKey: "MurmursAPIBaseURL") as? String).flatMap(URL.init(string:))
    }

    func createAccount() async throws -> AccountCredentials {
        let output = try await call { try await Client.murmurs(serverURL: serverURL).createAccount() }
        switch output {
        case .created(let response):
            let body = try response.body.json
            return AccountCredentials(userId: body.userId, token: body.token, recoveryCode: body.recoveryCode)
        case .tooManyRequests:
            throw AccountAPIError.rateLimited
        case .badRequest:
            throw AccountAPIError.server(statusCode: 400)
        case .internalServerError:
            throw AccountAPIError.server(statusCode: 500)
        case .undocumented(let statusCode, _):
            throw AccountAPIError.server(statusCode: statusCode)
        }
    }

    func recover(code: String) async throws -> AccountCredentials {
        let output = try await call {
            try await Client.murmurs(serverURL: serverURL).recoverSession(body: .json(.init(recoveryCode: code)))
        }
        switch output {
        case .ok(let response):
            let body = try response.body.json
            return AccountCredentials(userId: body.userId, token: body.token, recoveryCode: nil)
        case .unauthorized:
            throw AccountAPIError.invalidRecoveryCode
        case .tooManyRequests:
            throw AccountAPIError.rateLimited
        case .badRequest:
            throw AccountAPIError.server(statusCode: 400)
        case .internalServerError:
            throw AccountAPIError.server(statusCode: 500)
        case .undocumented(let statusCode, _):
            throw AccountAPIError.server(statusCode: statusCode)
        }
    }

    func rotateRecoveryCode(token: String) async throws -> String {
        let output = try await call {
            try await Client.murmurs(serverURL: serverURL, token: token).rotateRecoveryCode()
        }
        switch output {
        case .ok(let response):
            return try response.body.json.recoveryCode
        case .unauthorized:
            throw AccountAPIError.unauthorized
        case .badRequest:
            throw AccountAPIError.server(statusCode: 400)
        case .internalServerError:
            throw AccountAPIError.server(statusCode: 500)
        case .undocumented(let statusCode, _):
            throw AccountAPIError.server(statusCode: statusCode)
        }
    }

    func signOut(token: String) async throws {
        let output = try await call { try await Client.murmurs(serverURL: serverURL, token: token).signOut() }
        switch output {
        case .noContent:
            return
        case .unauthorized:
            throw AccountAPIError.unauthorized
        case .badRequest:
            throw AccountAPIError.server(statusCode: 400)
        case .internalServerError:
            throw AccountAPIError.server(statusCode: 500)
        case .undocumented(let statusCode, _):
            throw AccountAPIError.server(statusCode: statusCode)
        }
    }

    func deleteAccount(token: String) async throws {
        let output = try await call { try await Client.murmurs(serverURL: serverURL, token: token).deleteAccount() }
        switch output {
        case .noContent:
            return
        case .unauthorized:
            throw AccountAPIError.unauthorized
        case .badRequest:
            throw AccountAPIError.server(statusCode: 400)
        case .internalServerError:
            throw AccountAPIError.server(statusCode: 500)
        case .undocumented(let statusCode, _):
            throw AccountAPIError.server(statusCode: statusCode)
        }
    }

    /// Maps transport failures to `.network`.
    private func call<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch let error as AccountAPIError {
            throw error
        } catch {
            throw AccountAPIError.network
        }
    }
}
