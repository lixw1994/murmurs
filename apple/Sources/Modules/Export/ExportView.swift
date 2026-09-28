import SwiftUI
import SwiftData

struct ExportView: View {
    @State private var vm: ExportViewModel
    @Environment(\.dismiss) var dismiss

    init(context: ModelContext = DataContainer.shared.context) {
        self._vm = State(initialValue: ExportViewModel(context: context))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(selection: $vm.category) {
                        ForEach(ExportCategory.enabledCases, id: \.self) {
                            Text($0.displayName)
                                .tag($0)
                        }
                    } label: {
                        Text(L(.export_category))
                    }

                    Picker(selection: $vm.format) {
                        ForEach(ExportFormat.allCases, id: \.self) {
                            Text($0.displayName)
                                .tag($0)
                        }
                    } label: {
                        Text(L(.export_format))
                    }
                }

                Section {
                    Button {
                        vm.export()
                    } label: {
                        HStack {
                            Text(L(.export))
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(vm.showShareSheet)
                    .background(SharingViewController(isPresenting: $vm.showShareSheet) {
                        let av = UIActivityViewController(activityItems: [vm.fileToShare!], applicationActivities: nil)
                        if UIDevice.current.userInterfaceIdiom == .pad {
                           av.popoverPresentationController?.sourceView = UIView()
                        }
                        av.completionWithItemsHandler = { _, _, _, _ in
                            vm.showShareSheet = false
                        }
                        return av
                    })
                }
            }
            .navigationTitle(L(.export_data))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(L(.cancel))
                    }
                }
            }
            .alert(L(.error), isPresented: $vm.showError) {
            } message: {
                Text(vm.lastErrorMessage)
            }
        }
    }
}

#Preview {
    ExportView(context: DataContainer.preview.context)
        .preferredColorScheme(.dark)
        .modelContainer(DataContainer.preview.modelContainer)
}
