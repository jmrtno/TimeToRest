import SwiftUI

// MARK: - BreakBlockScreen
/// The friction screen shown when the user wants to break the block.
/// Shows a countdown, psychological messages, and the final break button.
struct BreakBlockScreen: View {

    @StateObject var viewModel: BreakBlockViewModel
    @EnvironmentObject private var router: Router

    var body: some View {
        countdownView
            .preferredColorScheme(.dark)
            .onAppear {
                viewModel.startCountdown()
            }
            .onDisappear {
                viewModel.stopTimer()
            }
    }

    // MARK: - Countdown View

    private var countdownView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Psychological message
            Text(viewModel.currentMessage)
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Streak message
            if let streakMsg = viewModel.streakMessage {
                Text(streakMsg)
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
            }

            // Countdown
            CountdownScreen(
                remaining: viewModel.countdownRemaining,
                total: viewModel.totalCountdown
            )
            .padding(.vertical, 16)

            // Actions
            VStack(spacing: 12) {
                // Go back — the right choice
                Button {
                    viewModel.stopTimer()
                    router.pop()
                } label: {
                    Text("Go back to rest")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .glassEffect(.regular.tint(.indigo.opacity(0.5)).interactive(), in: .rect(cornerRadius: 12))
                }

                // Break button — only enabled after countdown
                if viewModel.canBreak {
                    Button {
                        viewModel.breakRest()
                        router.popToRoot()
                    } label: {
                        Text("Yes, I want to use my phone")
                            .font(.subheadline)
                            .foregroundStyle(.red.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .glassEffect(.regular.tint(.red.opacity(0.1)).interactive(), in: .rect(cornerRadius: 12))
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.bottom, 15)
            .animation(.easeInOut(duration: 0.3), value: viewModel.canBreak)
        }
        .padding(.horizontal, 24)
    }
}
