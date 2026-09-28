import SwiftUI

struct MyEmptyView: View {
    let text: String
    var body: some View {
        ZStack {
            Color.clear
            VStack {
                Text(text)
                    .font(.title)
                    .fontWeight(.bold)
            }
            .offset(y: -80)
        }
    }
}


#Preview {
    MyEmptyView(text: "No Memos")
}
