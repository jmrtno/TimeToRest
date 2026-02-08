import SwiftUI

// MARK: - BreakBlockScreen
/// The friction screen shown when the user wants to break the block.
/// Shows a countdown, psychological messages, and the final break button.
struct BreakBlockScreen: View {

    @StateObject var viewModel: BreakBlockViewModel
    @EnvironmentObject private var router: Router

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.didBreak {
                brokenView
            } else {
                countdownView
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
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

            Text("⚠️")
                .font(.system(size: 48))

            Text("Are you sure?")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

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
            CountdownView(
                remaining: viewModel.countdownRemaining,
                total: viewModel.totalCountdown
            )
            .padding(.vertical, 16)

            Spacer()

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
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.15))
                        )
                }

                // Break button — only enabled after countdown
                if viewModel.canBreak {
                    Button {
                        viewModel.breakRest()
                    } label: {
                        Text("Yes, I want to use my phone")
                            .font(.subheadline)
                            .foregroundStyle(.red.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.bottom, 50)
            .animation(.easeInOut(duration: 0.3), value: viewModel.canBreak)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Broken View

    private var brokenView: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("💔")
                .font(.system(size: 64))

            Text("It's okay.")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Tomorrow is another chance.")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.5))

            Spacer()

            Button {
                router.popToRoot()
            } label: {
                Text("Close")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 24)
    }
}
