import SwiftUI

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .foregroundColor(.white)
            .background(Color(uiColor: .systemRed))
            .cornerRadius(14)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

#Preview {
    Button {
    } label: {
        Image(systemName: "trash")
    }
    .buttonStyle( DestructiveButtonStyle() )
}
