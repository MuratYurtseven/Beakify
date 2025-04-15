import SwiftUI

// Extension for convenience
extension View {
    func shake(isShaking: Bool) -> some View {
        self.modifier(ShakeEffect(animatableData: isShaking ? 1 : 0))
            .animation(.default, value: isShaking)
    }
} 
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

