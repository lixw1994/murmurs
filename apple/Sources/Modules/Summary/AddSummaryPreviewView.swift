import SwiftUI

struct AddSummaryPreviewView: View {
    @Environment(AddSummaryViewModel.self) var vm
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        @Bindable var vm = vm
        ZStack {
            Form {
                Section {
                    MyTextView(text: $vm.summaryMessage)
                } header: {
                    HStack {
                        Spacer()
                        Text("\(L(.characters)): \(vm.summaryMessageCharCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .headerProminence(.increased)
            }
        }
        .navigationTitle(L(.preview))
        .task {
            vm.generateMessage()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    hideKeyboard()
                    vm.navPath.append(.summarize)
                } label: {
                    Text(L(.summarize))
                }
                .disabled(vm.summaryMessage.isEmpty)
            }
        }
    }
}

#if DEBUG
#Preview {
    AddSummaryPreviewView()
        .environment(AddSummaryViewModel(item: SummaryItem.day(20230722), context: DataContainer.preview.context))
}
#endif
