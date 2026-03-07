import SwiftUI
import SwiftData

struct AddSummaryPromptView: View {
    @Environment(AppState.self) var appState
    @State private var vm: AddSummaryViewModel

    init(item: SummaryItem) {
        self._vm = State(initialValue: AddSummaryViewModel(item: item, context: DataContainer.shared.context))
    }

    @Environment(\.dismiss) var dismiss
    @Query(sort: \PromptEntity.createdAt) var prompts: [PromptEntity]
    
    var body: some View {
        NavigationStack(path: $vm.navPath) {
            ZStack {
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        if prompts.count == 0 {
                            addPromptButton()
                        } else {
                            promptsList()
                        }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $vm.showAddPrompt) {
                if vm.selectedPrompt == nil {
                    vm.selectedPrompt = prompts.first
                }
            } content: {
                AddUpdatePromptView()
            }
            .toolbar {
                toolbarItems()
            }
            .task {
                if prompts.count > 0 {
                    vm.selectedPrompt = prompts.first
                }
                vm.fetchEntries()
            }
            .alert(L(.error), isPresented: $vm.showFatalError) {
                Button(L(.ok)) {
                    dismiss()
                }
            } message: {
                Text(vm.fatalErrorMessage)
            }
            .navigationDestination(for: AddSummaryNavPath.self) { s in
                if s == .preview {
                    AddSummaryPreviewView()
                        .environment(vm)
                } else if s == .memoSelection {
                    AddSummaryMemoSelectionView()
                        .environment(vm)
                } else if s == .summarize {
                    AddSummarySummarizeView()
                        .environment(vm)
                }
            }
            .onChange(of: vm.saved) { oldValue, newValue in
                if newValue {
                    appState.activeTab = 1
                    dismiss()
                }
            }
        }
    }
    
    @ViewBuilder
    private func addPromptButton() -> some View {
        Text(L(.sum_no_prompts))
            .font(.title2)
            .fontWeight(.bold)
            .padding(5)
        FeedbackButton {
            vm.showAddPrompt = true
        } label: {
            Text(L(.sum_add_prompt))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 18)
                .background(.blue)
                .clipShape(RoundedRectangle(cornerRadius: .infinity))
        }
        .padding(5)
    }
    
    @ViewBuilder
    private func promptsList() -> some View {
        Text(L(.sum_choose_prompt))
            .font(.headline)
            .padding(5)
        ForEach(prompts) { p in
            Button {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                vm.selectedPrompt = p
            } label: {
                SummaryPromptEntryView(prompt: p, selected: vm.selectedPrompt == p)
            }
            .buttonStyle(NoEffectButtonStyle())
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarItems() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(role: .cancel) {
                dismiss()
            } label: {
                Text(L(.cancel))
            }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button {
                vm.navPath.append(.memoSelection)
            } label: {
                Text(L(.next))
            }
            .disabled(vm.selectedPrompt == nil)
        }
    }
}

#Preview {
    AddSummaryPromptView(item: SummaryItem.day(20231010))
}
