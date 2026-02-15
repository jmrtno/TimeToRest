import SwiftUI

// MARK: - HomeScreen
/// The main screen of the app.
/// Transforms inline into night mode when the rest window is active.
/// No separate night mode screen — the home screen itself changes.
struct HomeScreen: View {

    @ObservedObject var nightModeViewModel: NightModeViewModel
    @ObservedObject var restViewModel: RestInfoViewModel
    @EnvironmentObject private var router: Router
    @State private var currentView: ViewType = .home
    private let calculateStatsUseCase: CalculateStatsUseCase

    enum ViewType {
        case home
        case stats
    }

    init(
        nightModeViewModel: NightModeViewModel,
        restViewModel: RestInfoViewModel,
        calculateStatsUseCase: CalculateStatsUseCase
    ) {
        self.nightModeViewModel = nightModeViewModel
        self.restViewModel = restViewModel
        self.calculateStatsUseCase = calculateStatsUseCase
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                if nightModeViewModel.showNightMode {
                    NightModeView(viewModel: nightModeViewModel)
                } else {
                    VStack {
                        if currentView == .home {
                            RestInfoView(viewModel: restViewModel)
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
        .animation(.easeInOut(duration: 0.5), value: nightModeViewModel.showNightMode)
        .onAppear {
            nightModeViewModel.onAppear()
        }
        .onDisappear {
            nightModeViewModel.onDisappear()
        }
        .onChange(of: router.navigationPath) { _, newPath in
            if newPath.isEmpty {
                nightModeViewModel.reload()
            }
        }
    }
}
