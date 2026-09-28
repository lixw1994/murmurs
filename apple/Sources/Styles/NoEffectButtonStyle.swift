import SwiftUI

struct NoEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

#Preview {
    Button {

    } label: {
        Image(systemName: "plus")
            .background(.red)
    }.buttonStyle(NoEffectButtonStyle())
}
