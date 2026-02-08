import SwiftUI

// MARK: - AppCoordinator
/// The root view that orchestrates navigation for the application.
///
/// Owns the HomeViewModel so it persists across modal presentations
/// and can be reloaded when configuration changes.
struct AppCoordinator: View {

    @StateObject private var router: Router
    @StateObject private var homeViewModel: HomeViewModel
    private let viewFactory: RouteViewFactory
    private let timeToRestRepository: TimeToRestRepositoryContract

    init(dependencies: AppDependencies) {
        _router = StateObject(wrappedValue: Router())
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(
            fetchRestTimeUseCase: dependencies.fetchRestTimeUseCase,
            calculateStatsUseCase: dependencies.calculateStatsUseCase,
            startRestSessionUseCase: dependencies.startRestSessionUseCase,
            configRepository: dependencies.timeToRestRepository,
            sessionRepository: dependencies.restSessionRepository
        ))
        self.viewFactory = RouteViewFactory(dependencies: dependencies)
        self.timeToRestRepository = dependencies.timeToRestRepository
    }

    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            HomeScreen(viewModel: homeViewModel)
                .navigationDestination(for: Route.self) { route in
                    viewFactory.view(for: route)
                }
        }
        .environmentObject(router)
        .sheet(
            item: $router.restConfigurationMode,
            onDismiss: {
                router.popToRoot()
                homeViewModel.reloadAfterConfigChange()
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
        if !timeToRestRepository.hasConfiguration() {
            router.presentRestConfiguration(mode: .mandatory)
        }
    }
}
