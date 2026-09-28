import SwiftUI

struct MyTextView: View {
    @State private var height: CGFloat = .zero
    @Binding var text: String
    
    let minHeight: CGFloat
    let autoFocus: Bool

    init(text: Binding<String>, minHeight: CGFloat = .zero, autoFocus: Bool = false) {
        self._text = text
        self.minHeight = minHeight
        self.autoFocus = autoFocus
    }
    
    var body: some View {
        GeometryReader { geo in
            TextViewInternal(text: $text, width: geo.size.width, height: $height, minHeight: minHeight, autoFocus: autoFocus)
        }
        .frame(height: height)
    }
    
    private struct TextViewInternal: UIViewRepresentable {
        typealias Context = UIViewRepresentableContext<TextViewInternal>

        let width: CGFloat
        let minHeight: CGFloat
        let autoFocus: Bool
        @Binding var text: String
        @Binding var height: CGFloat

        init(text: Binding<String>, width: CGFloat, height: Binding<CGFloat>, minHeight: CGFloat, autoFocus: Bool = false) {
            self._text = text
            self.width = width
            self._height = height
            self.minHeight = minHeight
            self.autoFocus = autoFocus
        }
        
        func makeUIView(context: Context) -> UIView {
            let textView = UITextView()
            textView.font = .preferredFont(forTextStyle: .body)
            textView.delegate = context.coordinator
            textView.autocapitalizationType = .none
            textView.autocorrectionType = .no
            textView.isScrollEnabled = false
            textView.backgroundColor = .clear
            
            let view = UIView()
            view.addSubview(textView)

            return view
        }
        
        func updateUIView(_ view: UIView, context: Context) {
            let textView = view.subviews.first! as! UITextView
            
            if !context.coordinator.isEditing {
                textView.text = text
            }

            if context.coordinator.needsAutoFocus && !text.isEmpty {
                context.coordinator.needsAutoFocus = false
                DispatchQueue.main.async {
                    textView.becomeFirstResponder()
                }
            }
            
            let bounds = CGSize(width: width, height: height)
            
            DispatchQueue.main.async {
                let h = textView.sizeThatFits(bounds).height
//                height = textView.sizeThatFits(bounds).height
                height = max(h, minHeight)
                let size = CGSize(width: width, height: height)
                view.frame.size = size
                textView.frame.size = size
            }
            
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(text: $text, autoFocus: autoFocus)
        }
        
        class Coordinator: NSObject, UITextViewDelegate {
            var text: Binding<String>
            var isEditing: Bool = false
            var needsAutoFocus: Bool

            init(text: Binding<String>, autoFocus: Bool) {
                self.text = text
                self.needsAutoFocus = autoFocus
            }
            
            func textViewDidChange(_ textView: UITextView) {
                self.text.wrappedValue = textView.text
            }
            
            func textViewDidBeginEditing(_ textView: UITextView) {
                isEditing = true
            }
            
            func textViewDidEndEditing(_ textView: UITextView) {
                isEditing = false
            }
        }
    }
}
