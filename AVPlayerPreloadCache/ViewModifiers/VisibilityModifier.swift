import SwiftUI

struct VisibilityModifier: ViewModifier {
    let action: (Bool) -> Void

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            let frame = geometry.frame(in: .global)
                            let isVisible = frame.intersects(UIScreen.main.bounds)
                            action(isVisible)
                        }
                        .onDisappear {
                            action(false)
                        }
                }
            )
    }
}

extension View {
    func onVisibilityChanged(perform action: @escaping (Bool) -> Void) -> some View {
        self.modifier(VisibilityModifier(action: action))
    }
}
