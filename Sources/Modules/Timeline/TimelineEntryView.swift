import SwiftUI
import SwiftData

struct TimelineEntryView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var player: AudioPlayer
    @Environment(TimelineViewModel.self) var vm

    var memo: MemoEntity
    @Environment(AppState.self) var appState
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 10) {
                timeLabel()
                contentLabel()
                if let file = memo.file {
                    HStack {
                        playButton(file)
                    }
                    .padding(.top, 8)
                }
            }
            menu()
                .offset(y: -8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: (isSelected ? .secondarySystemFill : .quaternarySystemFill)))
        )
        .padding(.bottom, 15)
        .contextMenu {
            if !vm.isMultiSelectMode {
                if memo.viewContent.count > 0 { copyButton }
                if Config.shared.isServerSet && !memo.viewContent.isEmpty { polishButton }
                if memo.hasPolishedContent { deletePolishButton }
                editButton
                if Config.shared.isReadwiseSet && memo.needsSync { syncButton }
                if Config.shared.isReadwiseSet && memo.readwiseId != nil { unsyncButton }
                selectButton
                deleteButton
            }
        }
        .onTapGesture(count: 2) {
            if !vm.isMultiSelectMode {
                appState.activeSheet = .editMemo(memo)
            }
        }
        .onTapGesture {
            if vm.isMultiSelectMode {
                vm.toggleMemoSelection(memo)
            }
        }
    }
    
    @ViewBuilder
    private func timeLabel() -> some View {
        HStack {
            Text(memo.viewTime)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.app_timeline_time)

            if Config.shared.isReadwiseSet {
                if vm.syncingMemos.contains(memo) {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 12, height: 12)
                } else if memo.syncedAt != nil && !memo.needsSync {
                    Image(systemName: "checkmark.icloud")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                } else if memo.syncedAt != nil && memo.needsSync {
                    Image(systemName: "arrow.clockwise.icloud")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                }
            }

            Spacer()
        }
    }
    
    @ViewBuilder
    private func contentLabel() -> some View {
        if vm.transcribingMemos.contains(memo) {
            Text(L(.transcribing))
                .foregroundColor(.secondary)
        } else if vm.polishingMemos.contains(memo) {
            VStack(alignment: .leading, spacing: 10) {
                Text(memo.viewContent)
                    .foregroundColor(.app_timeline_text)
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text(L(.polishing))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                if memo.isHidden {
                    Text(memo.viewContent)
                        .redacted(reason: .placeholder)
                } else if memo.hasPolishedContent {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text(memo.viewPolishedContent)
                            .foregroundColor(.app_timeline_text)
                    }
                    Text(memo.viewContent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else {
                    Text(memo.viewContent)
                        .foregroundColor(.app_timeline_text)
                }
                if let err = vm.failedMemos[memo] {
                    Text(err.localizedDescription)
                        .font(.caption2)
                        .foregroundColor(.red)
                }
                if let err = vm.polishFailedMemos[memo] {
                    Text(err.localizedDescription)
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    @ViewBuilder
    private func menu() -> some View {
        if vm.isMultiSelectMode {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .green : .secondary)
        } else if vm.transcribingMemos.contains(memo) || vm.polishingMemos.contains(memo) {
            ProgressView()
        } else {
            Menu {
                if memo.file != nil && Config.shared.transEnabled { transButton }
                if Config.shared.isServerSet && !memo.viewContent.isEmpty { polishButton }
                if memo.hasPolishedContent { deletePolishButton }
                editButton
                if memo.viewContent.count > 0 { shareButton }
                if memo.file != nil { shareAudioButton }
                if Config.shared.isReadwiseSet && memo.needsSync { syncButton }
                if Config.shared.isReadwiseSet && memo.readwiseId != nil { unsyncButton }
                showHideButton
                deleteButton
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.app_timeline_time)
                    .frame(width: 30, height: 30)
            }
        }
    }
    
    @ViewBuilder
    private func playButton(_ file: String) -> some View {
        Button {
            if !player.isPlaying {
                player.play(file: file)
            } else {
                if file == player.currentFile {
                    player.stop()
                } else {
                    player.stop()
                    player.play(file: file)
                }
            }
        } label: {
            Image(systemName: player.isPlaying && file == player.currentFile ? "stop.fill" : "play.fill")
                .foregroundColor(player.isPlaying && file == player.currentFile ? .red : .secondary)
                .font(.system(size: 10))
                .frame(width: 24, height: 24)
                .background(Color(uiColor: .tertiarySystemFill))
                .clipShape(Circle())
                .animation(.none, value: player.isPlaying)
        }
    }
    
    @ViewBuilder
    private var deleteButton: some View {
        Button (role: .destructive) {
            vm.memoToDelete = memo
        } label: {
            Image(systemName: "trash")
            Text(L(.delete))
        }
    }
    
    @ViewBuilder
    private var editButton: some View {
        Button {
            appState.activeSheet = .editMemo(memo)
        } label: {
            Image(systemName: "square.and.pencil")
            Text(L(.edit))
        }
    }
    
    @ViewBuilder
    private var selectButton: some View {
        Button {
            vm.isMultiSelectMode = true
            vm.selectedMemos.insert(memo)
        } label: {
            Image(systemName: "checkmark.circle")
            Text(L(.select))
        }
    }

    @ViewBuilder
    private var shareButton: some View {
        ShareLink(item: memo.viewContent) {
            Image(systemName: "square.and.arrow.up")
            Text(L(.share))
        }
    }
    
    @ViewBuilder
    private var shareAudioButton: some View {
        if let file = memo.file {
            ShareLink(item: FileHelper.fullAudioURL(for: file)) {
                Image(systemName: "waveform")
                Text(L(.share_audio))
            }
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var copyButton: some View {
        Button {
            UIPasteboard.general.string = memo.viewContent
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Image(systemName: "doc.on.doc")
            Text(L(.copy))
        }
    }
    
    private var polishButton: some View {
        Button {
            vm.polish(memo)
        } label: {
            Image(systemName: "sparkles")
            if memo.hasPolishedContent {
                Text(L(.repolish))
            } else {
                Text(L(.polish))
            }
        }
    }

    private var deletePolishButton: some View {
        Button(role: .destructive) {
            vm.deletePolish(memo)
        } label: {
            Image(systemName: "sparkles.slash")
            Text(L(.delete_polish))
        }
    }

    private var transButton: some View {
        Button {
            vm.transcribe(memo)
        } label: {
            Image(systemName: "pencil.and.outline")
            if memo.transcribed {
                Text(L(.retranscribe))
            } else {
                Text(L(.transcribe))
            }
        }
    }
    
    private var syncButton: some View {
        Button {
            vm.syncToReadwise(memo)
        } label: {
            Image(systemName: "arrow.clockwise.icloud")
            Text(L(.readwise_sync))
        }
    }

    private var unsyncButton: some View {
        Button(role: .destructive) {
            vm.unsyncFromReadwise(memo)
        } label: {
            Image(systemName: "xmark.icloud")
            Text(L(.readwise_unsync))
        }
    }

    private var showHideButton: some View {
        Button {
            vm.toggleVisibility(memo)
        } label: {
            if memo.isHidden {
                Image(systemName: "eye")
                Text(L(.show))
            } else {
                Image(systemName: "eye.slash")
                Text(L(.hide))
            }
        }
    }
    
    private var isSelected: Bool {
        vm.isMultiSelectMode && vm.selectedMemos.contains(memo)
    }
}

#if DEBUG
#Preview {
    TimelineEntryView(memo: MemoEntity.preview(context: DataContainer.preview.context))
        .modelContainer(DataContainer.preview.modelContainer)
        .preferredColorScheme(.dark)
        .environmentObject(AudioPlayer())
        .environment(TimelineViewModel())
}
#endif
