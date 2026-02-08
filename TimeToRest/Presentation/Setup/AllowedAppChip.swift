import SwiftUI

// MARK: - AllowedAppChip
/// A selectable chip for allowed apps in the setup screen.
struct AllowedAppChip: View {
    let app: AllowedApp
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.caption)
                Text(displayName)
                    .font(.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(isSelected ? 0.4 : 0.2), lineWidth: 1)
            )
            .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
        }
        .buttonStyle(.plain)
    }

    private var displayName: String {
        switch app {
        case .phone: return "Phone"
        case .emergency: return "Emergency"
        case .spotify: return "Spotify"
        }
    }

    private var iconName: String {
        switch app {
        case .phone: return "phone.fill"
        case .emergency: return "cross.fill"
        case .spotify: return "music.note"
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack {
            AllowedAppChip(app: .phone, isSelected: true, onTap: {})
            AllowedAppChip(app: .spotify, isSelected: false, onTap: {})
        }
    }
}
