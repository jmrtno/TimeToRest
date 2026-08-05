import SwiftUI

// MARK: - SetupAICoachSectionView
/// Section that displays the AI sleep tip along with a subtle shimmer border.
struct SetupAICoachSectionView: View {

    let viewModel: SetupViewModel
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    @State private var didCoachCardSettle = false
    @State private var shimmerAngle: Double = 0

    // MARK: - Body
    var body: some View {
        Group {
            if viewModel.mode == .editable {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("AI Coach:")
                            .textCase(.uppercase)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.bottom, 16)
                        
                        if viewModel.isTipLoading || !didCoachCardSettle {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(.orange)
                                Text("Generating tip...")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(viewModel.sleepTip)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.85))
                                
                                if viewModel.sleepTip.contains("Apple Intelligence is not enabled") {
                                    Button("Open Settings") {
                                        if let url = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.orange)
                                }
                            }
                            .transition(.opacity)
                        }
                    }
                    
                    Spacer()
                }
                .padding(16)
                .glassEffect(.regular.tint(.orange.opacity(0.15)), in: .rect(cornerRadius: 24))
                .overlay {
                    if !reduceMotion {
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .clear, location: 0.0),
                                        .init(color: .clear, location: 0.43),
                                        .init(color: .orange.opacity(0.25), location: 0.47),
                                        .init(color: .orange.opacity(0.55), location: 0.50),
                                        .init(color: .orange.opacity(0.25), location: 0.53),
                                        .init(color: .clear, location: 0.57),
                                        .init(color: .clear, location: 1.0)
                                    ]),
                                    center: .center,
                                    angle: .degrees(shimmerAngle)
                                ),
                                lineWidth: 2.5
                            )
                    }
                }
                .task {
                    try? await Task.sleep(for: .seconds(0.2 + 0.9 + 1.4 + 0.05))
                    didCoachCardSettle = true
                    guard !reduceMotion else { return }
                    shimmerAngle = 0
                    while !Task.isCancelled {
                        withAnimation(.easeInOut(duration: 8)) {
                            shimmerAngle = 360
                        }
                        try? await Task.sleep(for: .seconds(8))
                        shimmerAngle = 0
                        try? await Task.sleep(for: .seconds(1.0))
                    }
                }
            }
        }
    }
}
