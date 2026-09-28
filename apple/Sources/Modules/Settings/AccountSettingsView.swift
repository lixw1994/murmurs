import SwiftUI

/// Settings → Account: recovery code, restore, and deletion (adr/0015).
struct AccountSettingsView: View {
    @State private var vm: AccountViewModel
    @State private var confirmRotate = false
    @State private var confirmDelete = false

    init(service: AccountService) {
        _vm = State(initialValue: AccountViewModel(service: service))
    }

    var body: some View {
        Form {
            Section {
                Text(vm.statusText)
            }

            if let code = vm.recoveryCode {
                Section {
                    if vm.isCodeRevealed {
                        Text(code)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                        Button(vm.didCopy ? L(.account_code_copied) : L(.copy)) {
                            vm.copyCode()
                        }
                    }
                    Button(vm.isCodeRevealed ? L(.account_hide_code) : L(.account_reveal_code)) {
                        vm.isCodeRevealed.toggle()
                        vm.didCopy = false
                    }
                    if vm.isReady {
                        Button(L(.account_rotate_code)) { confirmRotate = true }
                            .disabled(vm.isBusy)
                    }
                } header: {
                    Text(L(.account_recovery_code))
                } footer: {
                    Text(L(.account_recovery_code_footer))
                }
            }

            Section {
                TextField("XXXXX-XXXXX-XXXXX-XXXXX-XXXXX", text: $vm.restoreInput)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                Button(L(.account_restore_button)) {
                    Task { await vm.restore() }
                }
                .disabled(!vm.canRestore)
            } header: {
                Text(L(.account_restore))
            } footer: {
                Text(L(.account_restore_footer))
            }

            if vm.isReady {
                Section {
                    Button(L(.account_delete), role: .destructive) { confirmDelete = true }
                        .disabled(vm.isBusy)
                }
            }
        }
        .navigationTitle(L(.settings_account))
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if vm.isBusy { ProgressView() }
        }
        .confirmationDialog(L(.account_rotate_code_confirm), isPresented: $confirmRotate, titleVisibility: .visible) {
            Button(L(.account_rotate_code)) { Task { await vm.rotateCode() } }
            Button(L(.cancel), role: .cancel) {}
        }
        .confirmationDialog(L(.account_delete_confirm), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(L(.account_delete), role: .destructive) { Task { await vm.deleteAccount() } }
            Button(L(.cancel), role: .cancel) {}
        }
        .alert(L(.error), isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button(L(.ok), role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }
}
