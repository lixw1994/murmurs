import SwiftUI
import XLog
import Observation

@Observable final class ReadwiseSettingsViewModel {
    var token = ""
    var isVerifying = false
    var isVerified = false
    var lastErrorMessage = "" {
        didSet { showError = true }
    }
    var showError = false

    private let readwiseClient: ReadwiseClientProtocol
    private let config: any ConfigProtocol

    init(readwiseClient: ReadwiseClientProtocol = ReadwiseClient.shared,
         config: any ConfigProtocol = Config.shared) {
        self.readwiseClient = readwiseClient
        self.config = config
    }

    func load() {
        token = config.readwiseToken
    }

    func verify() {
        guard !isVerifying else { return }
        isVerifying = true
        Task { @MainActor in
            do {
                try await readwiseClient.verify(token: token)
                isVerified = true
            } catch {
                lastErrorMessage = ErrorHelper.desc(error)
            }
            isVerifying = false
        }
    }

    func save() {
        config.readwiseToken = token
        config.readwiseSyncEnabled = true
    }

    func disconnect() {
        config.readwiseToken = ""
        config.readwiseSyncEnabled = false
        token = ""
        isVerified = false
    }
}

struct ReadwiseSettingsView: View {
    @EnvironmentObject var config: Config
    @State private var vm = ReadwiseSettingsViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section {
                TextField("Token", text: $vm.token)
                    .font(.system(.footnote, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Readwise Access Token")
            } footer: {
                Link(L(.readwise_token_help),
                     destination: URL(string: "https://readwise.io/access_token")!)
                    .font(.caption)
            }

            Section {
                if config.isReadwiseSet {
                    Toggle(L(.readwise_auto_sync), isOn: $config.readwiseAutoSync)
                    Button(role: .destructive) {
                        vm.disconnect()
                    } label: {
                        Text(L(.readwise_disconnect))
                    }
                } else {
                    Button {
                        dismiss()
                        vm.save()
                    } label: {
                        Text(L(.save))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!vm.isVerified)
                }
            }
        }
        .navigationTitle("Readwise")
        .alert(L(.error), isPresented: $vm.showError) {
        } message: {
            Text(vm.lastErrorMessage)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if vm.isVerifying {
                    ProgressView()
                } else {
                    Button {
                        vm.verify()
                    } label: {
                        Text(L(.verify))
                    }
                    .disabled(vm.token.isEmpty)
                }
            }
        }
        .task {
            vm.load()
        }
    }
}

#Preview {
    ReadwiseSettingsView()
        .environmentObject(Config.shared)
}
