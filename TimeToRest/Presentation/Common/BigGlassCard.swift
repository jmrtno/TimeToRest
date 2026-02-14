import SwiftUI

struct BigGlassCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let value: String
    let color: Color
    let content: (() -> any View)?
    
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
                }
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
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
