import SwiftUI

struct AddSummarySummarizeView: View {
    @Environment(AddSummaryViewModel.self) var vm
    
    var body: some View {
        ZStack {
            ScrollView(.vertical) {
                LazyVStack {
                    if vm.summaryError.count > 0 {
                        errorView
                    }
                    Text(vm.summarizedResponse)
                        .foregroundColor(vm.isSummarizing ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 20)
                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal, 16)
            }
            
            if (!(vm.isSummarizing || vm.summarizedResponse.isEmpty)) {
                VStack {
                    Spacer()
                    FeedbackButton {
                        vm.save()
                    } label: {
                        Text(L(.save))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(20)
            }
        }
        .task {
            vm.summarize()
        }
        .onDisappear {
            vm.cancelTasks()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 10) {
                    VStack {
                        Text(vm.model.displayName)
                        Text("\(L(.prompt_temperature)): \(String(format: "%.1f", vm.temperature))")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                if vm.isSummarizing {
                    ProgressView()
                } else {
                    Menu {
                        Button {
                        } label: {
                            Text(L(.save))
                        }
                        
                        Button {
                            vm.summarize()
                        } label: {
                            Text(L(.resummarize))
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .disabled(vm.isSummarizing || vm.summarizedResponse.isEmpty)
                }
            }
        }
    }
    
    private var errorView: some View {
        VStack {
            Text(vm.summaryError)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 20)
            
            Button {
                vm.summarize()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text(L(.try_again))
                }
            }
            .buttonStyle(TryAgainButtonStyle())
        }
    }
}

#if DEBUG
#Preview {
    AddSummarySummarizeView()
        .environment(AddSummaryViewModel(item: SummaryItem.day(20230722), context: DataContainer.preview.context))
}
#endif
