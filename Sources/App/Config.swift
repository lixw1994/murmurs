import Foundation
import KeychainAccess
import SwiftUI
import Combine

struct StartupOption {
    static let record = "record"
    static let createNote = "create_note"
}

class Config: ObservableObject, ConfigProtocol {
    @AppStorage("day_start_time") var dayStartTime = 2
    @AppStorage("dark_mode") var darkMode = DarkMode.auto
    @AppStorage("trans_enabled") var transEnabled = false
    @AppStorage("trans_provider") var transProvider = TranscriptionProvider.apple
    @AppStorage("trans_lang") var transLang = TranscriptionLang.auto
    @AppStorage("trans_model") var transModel = TranscriptionModel.whisper_1
    
    @AppStorage("sum_enabled") var sumEnabled = false

    @AppStorage("chat_model") private var aiModelData: String = ""

    var aiModel: ChatModel {
        get {
            if aiModelData.isEmpty {
                // Migrate from legacy enum storage
                if let legacyRaw = UserDefaults.standard.string(forKey: "openai_model"),
                   let migrated = ChatModel.fromLegacy(legacyRaw) {
                    aiModelData = (try? String(data: JSONEncoder().encode(migrated), encoding: .utf8)) ?? ""
                    UserDefaults.standard.removeObject(forKey: "openai_model")
                    return migrated
                }
                return .default
            }
            guard let data = aiModelData.data(using: .utf8),
                  let model = try? JSONDecoder().decode(ChatModel.self, from: data) else {
                return .default
            }
            return model
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                aiModelData = json
            }
        }
    }
    
    @AppStorage("auto_save") var autoSave = true
    
    @AppStorage("server_host") var serverHost = "" {
        didSet {
            validateHost()
        }
    }
    
    // MARK: - Experimental Features
    
    /// 自定义 whisper 提示词
    @AppStorage("custom_whisper_prompt_enabled") var customWhisperPromptEnabled = false
    @AppStorage("custom_whisper_prompt") var customWhisperPrompt = ""
    
    /// Hold to Record
    @AppStorage("hold_to_record_enabled") var holdToRecordEnabled = false
    
    /// Auto Record / Create Note On Startup
    @AppStorage("auto_start_on_startup") var autoStartOnStartup = ""
    
    // MARK: - Readwise

    @AppStorage("readwise_sync_enabled") var readwiseSyncEnabled = false
    @AppStorage("readwise_auto_sync") var readwiseAutoSync = false

    @Published var readwiseToken: String = "" {
        didSet {
            if readwiseToken.isEmpty {
                keychain[READWISE_KEY_NAME] = nil
            } else {
                keychain[string: READWISE_KEY_NAME] = readwiseToken
            }
        }
    }

    var isReadwiseSet: Bool {
        readwiseSyncEnabled && !readwiseToken.isEmpty
    }

    @Published var colorScheme = ColorScheme.light

    static let shared = Config()

    private let keychain = Keychain(service: Bundle.main.bundleIdentifier!)

    private let KEY_NAME = "openai_api_key"
    private let READWISE_KEY_NAME = "readwise_token"

    private var cancellables = Set<AnyCancellable>()

    private init() {
        serverAPIKey = keychain[string: KEY_NAME] ?? ""
        readwiseToken = keychain[string: READWISE_KEY_NAME] ?? ""
        validateHost()
    }
    
    private func validateHost() {
        isServerSet = !serverHost.isEmpty
    }
    
    @Published var serverAPIKey: String = "" {
        didSet {
            if serverAPIKey.isEmpty {
                keychain[KEY_NAME] = nil
            } else {
                keychain[string: KEY_NAME] = serverAPIKey
            }
        }
    }
    
    @Published var isServerSet: Bool = false
    
    var isServerValid: Bool {
        if let _ = URL(string: serverHost), !serverHost.isEmpty {
            return true
        }
        return false
    }
}
