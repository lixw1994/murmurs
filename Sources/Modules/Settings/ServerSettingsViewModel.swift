import Foundation
import SwiftUI
import XLog
import Observation

enum ServerVerificationItem: CaseIterable {
    case gpt_4o
    case whisper

    var displayName: String {
        switch self {
        case .gpt_4o: return "GPT-4o"
        case .whisper: return "Whisper"
        }
    }
}

enum ServerVerificationStatus: Equatable {
    case pending
    case inProgress
    case success
    case failure(String)
}

@Observable final class ServerSettingsViewModel {
    var isVerifying = false {
        didSet {
            if isVerifying {
                for k in verificationItems.keys {
                    verificationItems[k] = .pending
                }
            }
        }
    }
    var lastErrorMessage = "" {
        didSet {
            showError = true
        }
    }
    var showError = false
    var isVerified = false

    var host = Constants.OpenAI.api_host {
        didSet { isVerified = false }
    }
    var requiresKey = false {
        didSet {
            isVerified = false
            if !requiresKey { key = "" }
        }
    }
    var key = "" {
        didSet { isVerified = false }
    }

    var verificationItems: [ServerVerificationItem: ServerVerificationStatus] = [ .gpt_4o: .pending, .whisper: .pending ]

    var isServerValid: Bool {
        if requiresKey { return !host.isEmpty && !key.isEmpty }
        return !host.isEmpty
    }

    private let config: any ConfigProtocol
    private let aiClient: AIClientProtocol

    init(aiClient: AIClientProtocol = OpenAIClient.shared, config: any ConfigProtocol = Config.shared) {
        self.aiClient = aiClient
        self.config = config
    }

    deinit{
        #if DEBUG
        XLog.debug("✖︎ ServerSettingsViewModel", source: "Server")
        #endif
    }

    func verify() {
        guard isVerifying == false else { return }

        host = host.formattedHostName()

        isVerifying = true

        Task { @MainActor in
            let keyToUse = requiresKey ? key : nil

            // 测试 gpt_4
            verificationItems[.gpt_4o] = .inProgress
            do {
                try await aiClient.verify(host, key: keyToUse, model: .default)
                verificationItems[.gpt_4o] = .success
            } catch {
                verificationItems[.gpt_4o] = .failure(ErrorHelper.desc(error))
            }

            // 测试 Whisper
            verificationItems[.whisper] = .inProgress
            do {
                try await aiClient.verifyWhisper(host, key: keyToUse)
                verificationItems[.whisper] = .success
            } catch {
                verificationItems[.whisper] = .failure(ErrorHelper.desc(error))
            }

            isVerified = verificationItems.filter { $0.value == .success }.count > 0
            isVerifying = false
        }

    }

    func save() {
        config.serverHost = host
        config.serverAPIKey = requiresKey ? key : ""
    }

    func load() {
        host = config.serverHost
        requiresKey = !config.serverAPIKey.isEmpty
        key = config.serverAPIKey
    }
}
