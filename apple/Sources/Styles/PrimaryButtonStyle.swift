import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.bold)
            .frame(height: 50)
            .background(bgColor(isPressed: configuration.isPressed))
            .foregroundColor(color(isPressed: configuration.isPressed))
            .cornerRadius(.infinity)
    }
    
    private func color(isPressed: Bool) -> Color {
        if !isEnabled {
            return Color.app_primary_btn_text_disabled
        }
        return Color.app_primary_btn_text
    }
    
    private func bgColor(isPressed: Bool) -> Color {
        return isPressed ? Color.app_primary_btn_bg_pressed : Color.app_primary_btn_bg
    }
}
    
#Preview {
    Button {

    } label: {
        Text("保存")
            .font(.headline)
    }
    .buttonStyle(PrimaryButtonStyle())
    .preferredColorScheme(.dark)
    .disabled(true)
}
