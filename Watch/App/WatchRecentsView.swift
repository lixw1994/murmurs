import SwiftUI
import SwiftData

struct WatchRecentsView: View {
    @Query(sort: \RecordingEntity.createdAt, order: .reverse) var items: [RecordingEntity]
    
    @State private var selectedItem: RecordingEntity?
    
    var body: some View {
        NavigationView {
            ZStack {
                if items.isEmpty {
                    Text(L(.watch_recents_empty))
                } else {
                    recordingList
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Text(L(.watch_recents))
                        .foregroundColor(.watch_nav_title)
                }
            }
        }
    }
    
    private var recordingList: some View {
        VStack {
            List {
                ForEach(items.prefix(10)) { item in
                    Button {
                        selectedItem = item
                    } label: {
                        VStack(alignment: .leading) {
                            Text(item.viewTitle)
                            Text(item.viewLength)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .fullScreenCover(item: $selectedItem) { v in
                if v.file != nil {
                    WatchPlayerView(recording: v)
                }
            }
        }
    }
}

#Preview {
    WatchRecentsView()
}
