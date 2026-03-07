import SwiftUI

struct SummaryEntryView: View {
    var summary: SummaryEntity
    var isSyncing: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(summary.viewTitle)
                    .font(.title3)
                    .fontWeight(.bold)

                if Config.shared.isReadwiseSet {
                    if isSyncing {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 12, height: 12)
                    } else if summary.syncedAt != nil && !summary.needsSync {
                        Image(systemName: "checkmark.icloud")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    } else if summary.syncedAt != nil && summary.needsSync {
                        Image(systemName: "arrow.clockwise.icloud")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Text(summary.truncatedContent(200))
                .foregroundColor(.secondary)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
            
            Divider()
                .background(Color(uiColor: .tertiarySystemBackground))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 15)
    }
}

#if DEBUG
#Preview {
    SummaryEntryView(summary: SummaryEntity.preview(context: DataContainer.preview.context))
        .preferredColorScheme(.dark)
        .modelContainer(DataContainer.preview.modelContainer)
}
#endif
