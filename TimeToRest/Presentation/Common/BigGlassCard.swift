import SwiftUI

struct BigGlassCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let value: String
    let color: Color
    let content: (() -> any View)?
    let animateNumbers: Bool
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        value: String,
        color: Color,
        animateNumbers: Bool = false,
        content: (() -> any View)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.color = color
        self.animateNumbers = animateNumbers
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.5))
                        .contentTransition(animateNumbers ? .numericText(countsDown: false) : .identity)
                        .animation(animateNumbers ? .default : nil, value: subtitle)
                }
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .contentTransition(animateNumbers ? .numericText(countsDown: false) : .identity)
                    .animation(animateNumbers ? .default : nil, value: value)
            }
            
            if let content {
                AnyView(content())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .glassEffect(in: .rect(cornerRadius: 24))
    }
}