import SwiftUI

// MARK: - AppCoordinator
/// The root view that orchestrates navigation for the application.
struct AppCoordinator: View {

    @StateObject private var router: Router
    @StateObject private var nightModeViewModel: NightModeViewModel
    @StateObject private var restViewModel: RestInfoViewModel
    private let viewFactory: RouteViewFactory
    private let fetchRestTimeUseCase: FetchRestTimeUseCase
    private let calculateStatsUseCase: CalculateStatsUseCase

    init(dependencies: AppDependencies) {
        _router = StateObject(wrappedValue: Router())
        _nightModeViewModel = StateObject(wrappedValue: NightModeViewModel(
            fetchRestTimeUseCase: dependencies.fetchRestTimeUseCase,
            startRestSessionUseCase: dependencies.startRestSessionUseCase,
            completeRestSessionUseCase: dependencies.completeRestSessionUseCase,
            fetchCurrentSessionUseCase: dependencies.fetchCurrentSessionUseCase
        ))
        _restViewModel = StateObject(wrappedValue: RestInfoViewModel(
            fetchRestTimeUseCase: dependencies.fetchRestTimeUseCase,
            calculateStatsUseCase: dependencies.calculateStatsUseCase
        ))
        self.viewFactory = RouteViewFactory(dependencies: dependencies)
        self.fetchRestTimeUseCase = dependencies.fetchRestTimeUseCase
        self.calculateStatsUseCase = dependencies.calculateStatsUseCase
    }

    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            HomeScreen(
                nightModeViewModel: nightModeViewModel,
                restViewModel: restViewModel,
                calculateStatsUseCase: calculateStatsUseCase
            )
                .navigationDestination(for: Route.self) { route in
                    viewFactory.view(for: route)
                }
        }
        .environmentObject(router)
        .sheet(
            item: $router.restConfigurationMode,
            onDismiss: {
                router.popToRoot()
                nightModeViewModel.reloadAfterConfigChange()
                restViewModel.reloadAfterConfigChange()
            },
            content: { mode in
                viewFactory.restConfigurationView(mode: mode)
                    .environmentObject(router)
            }
        )
        .onAppear {
            checkInitialConfiguration()
        }
    }

    private func checkInitialConfiguration() {
        if fetchRestTimeUseCase.execute() == nil {
            router.presentRestConfiguration(mode: .mandatory)
        }
    }
}
