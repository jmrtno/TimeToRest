import SwiftUI

// MARK: - StatCard
/// A reusable card component for displaying a single statistic.
struct StatsGlassCard: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color

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
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .glassEffect(in: .rect(cornerRadius: 24))
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        StatsGlassCard(icon: "moon.fill", title: "Current Streak", value: "4", iconColor: .indigo)
    }
}
