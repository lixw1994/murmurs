import SwiftUI

struct RecordingStatusView: View {
    var isPaused: Bool = false
    @State private var isRecording = false
    var body: some View {
        VStack {
            HStack(spacing: 20) {
                Circle()
                    .fill(isPaused ? .orange : .red)
                    .frame(width: 12, height: 12)
                    .opacity(isPaused ? 1 : (isRecording ? 1 : 0.4))
                Text(isPaused ? L(.pause).capitalized : L(.recording).capitalized)
                    .font(.system(size: 20, weight: .bold))
            }
            .offset(x: -15)
            .animation(isPaused ? nil : .linear(duration: 0.3).repeatForever(autoreverses: true), value: isRecording)
            Spacer()
        }
        .onAppear {
            isRecording = true
        }
    }
}

#Preview {
    RecordingStatusView()
}
