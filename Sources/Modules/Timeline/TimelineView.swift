import SwiftUI
import SwiftData
import StoreKit

struct TimelineView: View {
    @Environment(AppState.self) var appState
    @Environment(DataContainer.self) var container
    @EnvironmentObject var config: Config
    @Environment(\.modelContext) var modelContext
    @Environment(\.requestReview) var requestReview
    @Query(sort: [SortDescriptor(\MemoEntity.day, order: .reverse),
                  SortDescriptor(\MemoEntity.createdAt, order: .reverse)]) var allMemos: [MemoEntity]
    @StateObject private var player = AudioPlayer.shared
    @State private var vm = TimelineViewModel()
    @State private var showCalendar = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var searchText = ""

    var daysWithMemos: Set<Int> {
        Set(allMemos.map { Int($0.day) })
    }

    private var isSearching: Bool {
        !searchText.isEmpty
    }

    private var searchResults: [MemoEntity] {
        guard isSearching else { return [] }
        return allMemos.filter { $0.matchesSearch(searchText) }
    }

    var sections: [(day: Int32, memos: [MemoEntity])] {
        Dictionary(grouping: allMemos, by: \.day)
            .sorted { $0.key > $1.key }
            .map { ($0.key, $0.value) }
    }

    var body: some View {
        @Bindable var vm = vm
        NavigationStack {
            ZStack {
                if allMemos.isEmpty {
                    MyEmptyView(text: L(.timeline_empty))
                } else if isSearching {
                    searchResultsList
                        .environmentObject(player)
                        .environment(vm)
                } else {
                    VStack(spacing: 0) {
                        if showCalendar {
                            CalendarView(daysWithMemos: daysWithMemos) { dayId in
                                withAnimation {
                                    scrollProxy?.scrollTo(dayId, anchor: .top)
                                }
                            }
                            Divider()
                        }
                        timelineList
                            .environmentObject(player)
                            .environment(vm)
                    }
                }
                if vm.isHoldingToRecord {
                    Color.black.opacity(0.8)
                }

                if !vm.isMultiSelectMode && !isSearching {
                    recordButton
                }
            }
            .modifier(SearchableModifier(text: $searchText, isEnabled: !allMemos.isEmpty))
            .background(Color.app_bg)
            .toolbar {
                toolbarContent
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                appState.checkMicPermission()
            }
            .onDisappear {
                stopPlayer()
            }
            .alert(isPresented: $vm.showDeleteAlert) {
                Alert(title: Text(L(.are_you_sure)),
                      message: vm.isMultiSelectMode ? Text(L(.multi_delete_alert, vm.selectedMemos.count)) : nil,
                      primaryButton: .destructive(Text(L(.delete))) {
                        vm.deleteSelectedMemos(context: modelContext)
                      }, secondaryButton: .cancel() {
                      })
            }
            .onChange(of: vm.showReviewDialog) { oldValue, newValue in
                guard newValue else { return }
                requestReview()
            }
        }
    }

    private func stopPlayer() {
        player.stop()
    }

    @ViewBuilder private var timelineList: some View {
        ScrollView {
            ScrollViewReader { scroll in
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    ForEach(sections, id: \.day) { section in
                        Section {
                            ForEach(section.memos) { item in
                                TimelineEntryView(memo: item)
                                    .padding(.horizontal, 16)
                            }
                        } header: {
                            TimelineHeaderView(dayId: Int(section.day))
                                .id(Int(section.day))
                        }
                    }
                    Spacer()
                        .frame(height: 90)
                }
                .onAppear { scrollProxy = scroll }
            }
        }
    }

    @ViewBuilder private var searchResultsList: some View {
        if searchResults.isEmpty {
            VStack {
                Spacer()
                Text(L(.search_no_results))
                    .foregroundColor(.secondary)
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(searchResults) { item in
                        VStack(alignment: .leading, spacing: 0) {
                            Text(item.viewCreatedAt)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.top, 4)
                            TimelineEntryView(memo: item)
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder private var recordButton: some View {
        VStack {
            Spacer()

            if allMemos.isEmpty && !vm.isHoldingToRecord {
                VStack(spacing: 15) {
                    Group {
                        Text(config.holdToRecordEnabled ? L(.timeline_recbtn_hold_here) : L(.timeline_recbtn_tap_here))
                        Image(systemName: "arrow.down")
                    }
                    .font(.subheadline)
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 15)
            }

            if !config.holdToRecordEnabled {
                FeedbackButton(action: startRecording) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 25))
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 64, height: 64)
                }
                .background(.red)
                .clipShape(Circle())
                .accessibilityIdentifier("microphone")
            } else {
                HoldToRecordView {
                    beginHoldToRecord()
                } onStop: {
                    endHoldToRecord()
                } onCancel: {
                    cancelHoldToRecord()
                }
            }
        }
        .padding(.bottom, 20)
    }

    private func startRecording() {
        appState.startRecording()
    }

    private func beginHoldToRecord() {
        guard appState.canStartRecording() else { return }
        vm.beginHoldToRecord()
    }

    private func endHoldToRecord() {
        vm.endHoldToRecord()
    }

    private func cancelHoldToRecord() {
        vm.cancelHoldToRecord()
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if vm.isMultiSelectMode {
            multiSelectToolbarItems
        } else {
            defaultToolbarItems
        }
    }

    @ToolbarContentBuilder
    private var defaultToolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                stopPlayer()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    appState.activeSheet = .settings
                }
            } label: {
                Image("nav_settings")
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 12) {
                if !allMemos.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showCalendar.toggle()
                        }
                    } label: {
                        Image(systemName: showCalendar ? "calendar.circle.fill" : "calendar")
                    }
                }

                Button {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        appState.activeSheet = .quickMemo
                    }
                } label: {
                    Image("nav_quick_memo")
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var multiSelectToolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                vm.isMultiSelectMode = false
                vm.selectedMemos.removeAll()
            } label: {
                Text(L(.cancel))
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                vm.showDeleteAlert = true
            } label: {
                Image(systemName: "trash")
            }
            .foregroundStyle(vm.selectedMemos.isEmpty ? Color.gray : Color.red)
            .disabled(vm.selectedMemos.isEmpty)
        }
    }
}

private struct SearchableModifier: ViewModifier {
    @Binding var text: String
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content.searchable(text: $text, prompt: L(.search_placeholder))
        } else {
            content
        }
    }
}

#if DEBUG
#Preview {
    TimelineView()
        .environment(AppState.shared)
        .environment(DataContainer.shared)
}
#endif
