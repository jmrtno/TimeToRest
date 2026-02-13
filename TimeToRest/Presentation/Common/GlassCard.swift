import SwiftUI

// MARK: - StatCard
/// A reusable card component for displaying a single statistic.
struct GlassCard: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 25, weight: .medium))
                    .foregroundStyle(iconColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Text(value)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            Spacer()
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
        GlassCard(icon: "moon.fill", title: "Current Streak", value: "4", iconColor: .indigo)
    }
}
