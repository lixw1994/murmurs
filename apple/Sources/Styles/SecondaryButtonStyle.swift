import SwiftUI

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(14)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

#Preview {
    VStack {
        Button("Cancel") {
        }
        .buttonStyle(SecondaryButtonStyle())
    }
}
