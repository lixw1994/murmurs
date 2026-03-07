import SwiftUI

struct MyToggle<Label: View>: View {
    @Environment(AppState.self) var appState
    @Binding var isOn: Bool
    
    let label: () -> Label
    
    init(isOn: Binding<Bool>,  @ViewBuilder label: @escaping () -> Label) {
        self._isOn = isOn
        self.label = label
    }
    
    var body: some View {
        Toggle(isOn: $isOn, label: label)
            .tint(.green)
    }
}

#Preview {
    MyToggle(isOn: .constant(true)) {
        Text("hello")
    }
}
