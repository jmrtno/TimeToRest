import SwiftUI

// MARK: - HomeScreen
/// The main screen of the app.
/// Transforms inline into night mode when the rest window is active.
/// No separate night mode screen — the home screen itself changes.
struct HomeScreen: View {

    var nightModeViewModel: NightModeViewModel
    var restViewModel: RestInfoViewModel
    var statsViewModel: StatsViewModel
    @Environment(Router.self) private var router
    @State private var currentView: ViewType = .home

    enum ViewType {
        case home
        case stats
    }

    init(
        nightModeViewModel: NightModeViewModel,
        restViewModel: RestInfoViewModel,
        statsViewModel: StatsViewModel
    ) {
        self.nightModeViewModel = nightModeViewModel
        self.restViewModel = restViewModel
        self.statsViewModel = statsViewModel
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                if nightModeViewModel.showNightMode {
                    NightModeScreen(viewModel: nightModeViewModel)
                } else {
                    VStack {
                        if currentView == .home {
                            RestInfoScreen(viewModel: restViewModel)
                        } else {
                            StatsScreen(statsViewModel: statsViewModel)
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
        .onChange(of: router.path) { _, newPath in
            if newPath.isEmpty {
                nightModeViewModel.reload()
            }
        }
    }
}
