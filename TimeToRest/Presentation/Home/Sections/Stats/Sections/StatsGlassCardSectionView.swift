import SwiftUI

// MARK: - StatCard
/// A reusable card component for displaying a single statistic.
struct StatsGlassCardSectionView: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color
    let animateNumbers: Bool
    
    init(
        icon: String,
        title: String,
        value: String,
        iconColor: Color,
        animateNumbers: Bool = false
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.iconColor = iconColor
        self.animateNumbers = animateNumbers
    }

    var body: some View {
        HStack {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 25, weight: .medium))
                        .foregroundStyle(iconColor)
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(value)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .contentTransition(animateNumbers ? .numericText(countsDown: false) : .identity)
                        .animation(animateNumbers ? .default : nil, value: value)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .glassEffect(in: .rect(cornerRadius: 24))
    }
}

#if DEBUG
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        StatsGlassCardSectionView(icon: "moon.fill",
                                  title: "Current Streak",
                                  value: "4",
                                  iconColor: .indigo)
    }
}
#endif
