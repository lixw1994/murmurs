import SwiftUI

struct TryAgainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .foregroundColor(.secondary)
            .background(Color(uiColor: .tertiarySystemFill))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
}

#Preview {
    Button {

    } label: {
        HStack {
            Image(systemName: "arrow.clockwise")
            Text("Try Again")
        }
    }
    .buttonStyle(TryAgainButtonStyle())
    .preferredColorScheme(.dark)
}
