import SwiftUI
import SwiftData

struct MemoEditView: View {
    var memo: MemoEntity

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var content: String = ""
    @State private var time = Date()
    
    @StateObject var player = AudioPlayer.shared
    
    init(memo: MemoEntity) {
        self.memo = memo
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    MyTextView(text: $content, minHeight: 120, autoFocus: true)
                } header: {
                    Text(L(.memo))
                }
                
                Section {
                    DatePicker(selection: $time, displayedComponents: [.date, .hourAndMinute]) {
                        Text(L(.time))
                    }
                    .tint(.gray)
                } footer: {
                    if memo.file != nil {
                        playerView()
                            .padding(.top, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        Text(L(.cancel))
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button() {
                        memo.content = content
                        memo.updateCreationTime(time)
                        memo.updatedAt = Date()
                        try? modelContext.save()
                        NotificationCenter.default.post(name: .memoInserted, object: memo)
                        dismiss()
                    } label: {
                        Text(L(.save))
                    }
                }
            }
        }
        .task {
            content = memo.viewContent
            time = memo.createdAt ?? Date()
            player.stop()
        }
    }
    
    @ViewBuilder
    private func playerView() -> some View {
        VStack(spacing: 30) {
            HStack {
                Button {
                    player.isPlaying ? player.stop() : player.play(file: memo.file!)
                } label: {
                    Image(systemName: player.isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .clipShape(Circle())
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

}

#if DEBUG
#Preview {
    MemoEditView(memo: MemoEntity.preview(context: DataContainer.preview.context))
        .modelContainer(DataContainer.preview.modelContainer)
}
#endif
