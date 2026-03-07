import SwiftUI
import SwiftData
import XLog
import TPPDF

struct SummaryDetailView: View {
    var summary: SummaryEntity

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(AppState.self) var appState
    
    @State private var showDeleteAlert = false
    @State private var isSyncing = false

    var body: some View {
        ScrollView(.vertical) {
            VStack {
                Text(summary.viewContent)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
            .toolbar {
                ToolbarItem {
                    Menu {
                        ShareLink(item: summary.shareContent) {
                            Image(systemName: "square.and.arrow.up")
                            Text(L(.share))
                        }

                        Button {
                            UIPasteboard.general.string = summary.shareContent
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Image(systemName: "doc.on.doc")
                            Text(L(.copy))
                        }

                        Button {
                            appState.activeSheet = .editSummary(summary)
                        } label: {
                            Image(systemName: "square.and.pencil")
                            Text(L(.edit))
                        }
                        
                        if Config.shared.isReadwiseSet && summary.needsSync {
                            Button {
                                syncToReadwise()
                            } label: {
                                Image(systemName: "arrow.clockwise.icloud")
                                Text(L(.readwise_sync))
                            }
                            .disabled(isSyncing)
                        }

                        if Config.shared.isReadwiseSet && summary.readwiseId != nil {
                            Button(role: .destructive) {
                                unsyncFromReadwise()
                            } label: {
                                Image(systemName: "xmark.icloud")
                                Text(L(.readwise_unsync))
                            }
                            .disabled(isSyncing)
                        }

                        Menu(L(.export)) {
                            Button {
                                ShareHelper.share(items: [markdown()])
                            } label: {
                                Text("Markdown")
                            }
                            
                            Button {
                                ShareHelper.share(items: [pdf()])
                            } label: {
                                Text("PDF")
                            }
                        }
                        
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                            Text(L(.delete))
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .alert(isPresented: $showDeleteAlert) {
                Alert(title: Text(L(.are_you_sure)), primaryButton: .destructive(Text(L(.delete))) {
                    modelContext.delete(summary)
                    try? modelContext.save()
                    dismiss()
                }, secondaryButton: .cancel())
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(summary.viewTitle)
    }
    
    private func syncToReadwise() {
        isSyncing = true
        Task {
            do {
                let documentId = try await ReadwiseClient.shared.save(summary: summary)
                summary.readwiseId = documentId
                summary.syncedAt = Date()
                try? modelContext.save()
            } catch {
                XLog.error("Readwise sync failed: \(error)", source: "Summary")
            }
            isSyncing = false
        }
    }

    private func unsyncFromReadwise() {
        guard let documentId = summary.readwiseId else { return }
        isSyncing = true
        Task {
            do {
                try await ReadwiseClient.shared.delete(documentId: documentId)
                summary.readwiseId = nil
                summary.syncedAt = nil
                try? modelContext.save()
            } catch {
                XLog.error("Readwise unsync failed: \(error)", source: "Summary")
            }
            isSyncing = false
        }
    }

    private func markdown() -> URL {
        let url = fileName(ext: "md")
        try? summary.shareContent.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    private func pdf() -> URL {
        let url = fileName(ext: "pdf")
        let document = PDFDocument(format: .a4)
        
        let title = NSMutableAttributedString(string: summary.viewTitle, attributes: [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 24, weight: .bold)
        ])
        document.add(attributedTextObject: PDFAttributedText(text: title))
        document.add(.contentLeft, text: "\n\n")
        let content = PDFSimpleText(text: summary.viewContent, spacing: 10)
        document.add(textObject: content)
        let generator = PDFGenerator(document: document)
        try? generator.generate(to: url)
        return url
    }
    
    private func fileName(ext: String = "md") -> URL {
        let illegalCharacters = CharacterSet(charactersIn: "/*\"<>&$`~:;%?\\")
        let fileName = summary.viewTitle.components(separatedBy: illegalCharacters).joined()
        let url = URL(filePath: NSTemporaryDirectory()).appending(path: "summary-\(fileName).\(ext)")
        XLog.debug("Export summary to \(url)", source: "Export")
        return url
    }
}

#if DEBUG
#Preview {
    SummaryDetailView(summary: SummaryEntity.preview(context: DataContainer.preview.context))
        .preferredColorScheme(.dark)
        .modelContainer(DataContainer.preview.modelContainer)
}
#endif
