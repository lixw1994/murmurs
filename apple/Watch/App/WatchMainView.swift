import SwiftUI

struct WatchMainView: View {
    var body: some View {
        TabView {
            WatchRecordView()
            WatchRecentsView()
        }
        .tabViewStyle(.page)
    }
}

#Preview {
    WatchMainView()
}
