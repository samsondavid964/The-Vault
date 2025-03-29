import SwiftUI

enum Theme {
    static let primaryColor = Color.blue
    static let secondaryColor = Color.blue
    static let backgroundColor = Color(.systemBackground)
    static let cardBackground = Color(.systemBackground)
    static let textColor = Color(.label)
    static let secondaryTextColor = Color(.secondaryLabel)
    
    static let shadowColor = Color.black.opacity(0.1)
    static let shadowRadius: CGFloat = 10
    static let shadowY: CGFloat = 5
    
    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 12
    
    static let animation = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    static let cardPadding: CGFloat = 16
    static let standardPadding: CGFloat = 20
    static let smallPadding: CGFloat = 12
    
    static let titleFont = Font.title.weight(.bold)
    static let headlineFont = Font.headline.weight(.semibold)
    static let bodyFont = Font.body
    static let captionFont = Font.caption.weight(.medium)
    
    static let gradientColors = [
        Color.blue.opacity(0.8),
        Color.blue.opacity(0.6)
    ]
    
    static let shimmerColors = [
        Color.white.opacity(0.0),
        Color.white.opacity(0.05),
        Color.white.opacity(0.0)
    ]
}

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: Theme.shimmerColors),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: phase
                    )
                }
            )
            .onAppear {
                phase = 1
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
} 