import SwiftUI
import SwiftData

struct SummaryEditView: View {
    var summary: SummaryEntity

    @State private var title = ""
    @State private var content = ""

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    init(summary: SummaryEntity) {
        self.summary = summary
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L(.sum_title), text: $title)
                } header: {
                    Text(L(.sum_title))
                }
                
                Section {
                    MyTextView(text: $content, minHeight: 200)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(L(.cancel))
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                        dismiss()
                    } label: {
                        Text(L(.save))
                    }
                    .disabled(title.isEmpty || content.isEmpty || (title == summary.viewTitle && content == summary.viewContent))
                }
            }
        }
        .onAppear {
            title = summary.viewTitle
            content = summary.viewContent
        }
    }
    
    private func save() {
        summary.title = title
        summary.content = content
        do {
            try modelContext.save()
        } catch {
        }
    }
}

#if DEBUG
#Preview {
    SummaryEditView(summary: SummaryEntity.preview(context: DataContainer.preview.context))
        .modelContainer(DataContainer.preview.modelContainer)
}
#endif
