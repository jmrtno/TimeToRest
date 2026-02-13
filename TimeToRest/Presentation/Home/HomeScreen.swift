import SwiftUI

// MARK: - HomeScreen
/// The main screen of the app.
/// Transforms inline into night mode when the rest window is active.
/// No separate night mode screen — the home screen itself changes.
struct HomeScreen: View {

    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var restViewModel: RestViewModel
    @EnvironmentObject private var router: Router
    @State private var currentView: ViewType = .home
    private let calculateStatsUseCase: CalculateStatsUseCase
    
    enum ViewType {
        case home
        case stats
    }
    
    init(
        viewModel: HomeViewModel,
        restViewModel: RestViewModel,
        calculateStatsUseCase: CalculateStatsUseCase
    ) {
        self.viewModel = viewModel
        self.restViewModel = restViewModel
        self.calculateStatsUseCase = calculateStatsUseCase
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                // Contenido principal
                if viewModel.showNightMode {
                    nightModeContent
                } else {
                    VStack {
                        if currentView == .home {
                            RestView(viewModel: restViewModel)
                        } else {
                            StatsView(calculateStatsUseCase: calculateStatsUseCase)
                        }
                        // Barra de navegación inferior
                        CustomTabBar(currentView: $currentView)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.5), value: viewModel.showNightMode)
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onChange(of: router.navigationPath) { _, newPath in
            if newPath.isEmpty {
                viewModel.reload()
                restViewModel.reload()
            }
        }
    }

    // MARK: - Night Mode Content (inline)

    private var nightModeContent: some View {
        VStack(spacing: 40) {
            Spacer()

            Text("😴")
                .font(.system(size: 80))

            VStack(spacing: 16) {
                Text("Time to rest.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Come back tomorrow")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.5))

                if let lateMessage = viewModel.lateMessage {
                    Text(lateMessage)
                        .font(.subheadline)
                        .foregroundStyle(.orange.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }

            Spacer()
            
            Text("Keep the app open to track your streak")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.3))

            VStack(spacing: 16) {
                // Break the block
                Button {
                    router.push(.breakBlock)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(viewModel.isStrictMode ? .caption2 : .caption)
                        Text("Break the block")
                            .font(viewModel.isStrictMode ? .caption : .subheadline)
                    }
                    .foregroundStyle(.red.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, viewModel.isStrictMode ? 10 : 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 24)
    }
}
