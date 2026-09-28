import Foundation
import Observation
import UIKit

/// State for the Account section of Settings (adr/0015).
@MainActor
@Observable
final class AccountViewModel {
    private let service: AccountService
    private let copyToPasteboard: (String) -> Void

    var isCodeRevealed = false
    var restoreInput = ""
    var errorMessage: String?
    var didCopy = false
    private(set) var isBusy = false

    init(
        service: AccountService,
        copyToPasteboard: @escaping (String) -> Void = { UIPasteboard.general.string = $0 }
    ) {
        self.service = service
        self.copyToPasteboard = copyToPasteboard
    }

    var state: AccountService.State { service.state }
    var recoveryCode: String? { service.recoveryCode }
    var isReady: Bool { if case .ready = service.state { true } else { false } }
    var canRestore: Bool { !isBusy && RecoveryCodeFormat.normalized(restoreInput) != nil }

    var statusText: String {
        switch service.state {
        case .ready: L(.account_status_ready)
        case .none: L(.account_status_none)
        case .working: L(.account_status_working)
        case .needsRestore: L(.account_status_needs_restore)
        }
    }

    func copyCode() {
        guard let code = recoveryCode else { return }
        copyToPasteboard(code)
        didCopy = true
    }

    func rotateCode() async {
        await run {
            _ = try await self.service.rotateRecoveryCode()
            self.isCodeRevealed = true
        }
    }

    func restore() async {
        await run {
            try await self.service.restore(code: self.restoreInput)
            self.restoreInput = ""
        }
    }

    func deleteAccount() async {
        await run {
            try await self.service.deleteAccount()
            self.isCodeRevealed = false
        }
    }

    private func run(_ action: @escaping () async throws -> Void) async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            try await action()
        } catch let error as AccountAPIError {
            errorMessage = Self.message(for: error)
        } catch {
            errorMessage = L(.account_error_generic)
        }
    }

    static func message(for error: AccountAPIError) -> String {
        switch error {
        case .invalidRecoveryCode: L(.account_error_invalid_code)
        case .network: L(.account_error_network)
        case .rateLimited: L(.account_error_rate_limited)
        case .unauthorized: L(.account_status_needs_restore)
        case .server: L(.account_error_generic)
        }
    }
}
