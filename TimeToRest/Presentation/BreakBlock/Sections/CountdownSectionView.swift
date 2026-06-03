import SwiftUI

// MARK: - CountdownScreen
/// A circular countdown timer display used in the break block flow.
struct CountdownSectionView: View {
    let remaining: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(remaining) / Double(total)
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 6)
                .frame(width: 120, height: 120)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.orange,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: remaining)

            // Number
            Text("\(remaining)")
                .font(.system(size: 44, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
        }
    }
}

#if DEBUG
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        CountdownSectionView(remaining: 7, total: 10)
    }
}
#endif
