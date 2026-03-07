import SwiftUI
import SwiftData
import XLog

struct SummaryView: View {
    @Query(sort: \SummaryEntity.createdAt, order: .reverse) var items: [SummaryEntity]
    @Environment(\.modelContext) var modelContext

    @State private var syncingSummaries: Set<String> = []
    @State private var summaryToDelete: SummaryEntity?

    var body: some View {
        NavigationStack {
            ZStack {
                if items.isEmpty {
                    MyEmptyView(text: L(.summary_empty))
                } else {
                    ScrollView(.vertical) {
                        LazyVStack {
                            ForEach(items) { item in
                                NavigationLink(destination: SummaryDetailView(summary: item)) {
                                    SummaryEntryView(summary: item, isSyncing: syncingSummaries.contains(item.entityId ?? ""))
                                }
                                .contextMenu {
                                    Button {
                                        UIPasteboard.general.string = item.shareContent
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    } label: {
                                        Label(L(.copy), systemImage: "doc.on.doc")
                                    }

                                    if Config.shared.isReadwiseSet && item.needsSync {
                                        Button {
                                            syncToReadwise(item)
                                        } label: {
                                            Label(L(.readwise_sync), systemImage: "arrow.clockwise.icloud")
                                        }
                                    }

                                    if Config.shared.isReadwiseSet && item.readwiseId != nil {
                                        Button(role: .destructive) {
                                            unsyncFromReadwise(item)
                                        } label: {
                                            Label(L(.readwise_unsync), systemImage: "xmark.icloud")
                                        }
                                    }

                                    Button(role: .destructive) {
                                        summaryToDelete = item
                                    } label: {
                                        Label(L(.delete), systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(L(.summary))
            .navigationBarTitleDisplayMode(.inline)
            .alert(L(.are_you_sure), isPresented: Binding(
                get: { summaryToDelete != nil },
                set: { if !$0 { summaryToDelete = nil } }
            )) {
                Button(L(.delete), role: .destructive) {
                    if let summary = summaryToDelete {
                        modelContext.delete(summary)
                        try? modelContext.save()
                        summaryToDelete = nil
                    }
                }
                Button(L(.cancel), role: .cancel) {
                    summaryToDelete = nil
                }
            }
        }
    }

    private func syncToReadwise(_ summary: SummaryEntity) {
        guard let entityId = summary.entityId else { return }
        guard !syncingSummaries.contains(entityId) else { return }

        syncingSummaries.insert(entityId)
        Task {
            do {
                let documentId = try await ReadwiseClient.shared.save(summary: summary)
                summary.readwiseId = documentId
                summary.syncedAt = Date()
                try? modelContext.save()
            } catch {
                XLog.error("Readwise sync failed: \(error)", source: "Summary")
            }
            syncingSummaries.remove(entityId)
        }
    }

    private func unsyncFromReadwise(_ summary: SummaryEntity) {
        guard let entityId = summary.entityId else { return }
        guard let documentId = summary.readwiseId else { return }
        guard !syncingSummaries.contains(entityId) else { return }

        syncingSummaries.insert(entityId)
        Task {
            do {
                try await ReadwiseClient.shared.delete(documentId: documentId)
                summary.readwiseId = nil
                summary.syncedAt = nil
                try? modelContext.save()
            } catch {
                XLog.error("Readwise unsync failed: \(error)", source: "Summary")
            }
            syncingSummaries.remove(entityId)
        }
    }
}

#Preview {
    SummaryView()
}
