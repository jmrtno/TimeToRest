import SwiftUI

// MARK: - AppCoordinator
/// The root view that orchestrates navigation for the application.
///
/// `AppCoordinator` sets up the main `NavigationStack`, manages modal presentations,
/// and coordinates the lifecycle of ViewModels. It acts as the composition root
/// for the UI layer, wiring together dependencies and handling system events.
struct AppCoordinator: View {

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var router: Router
    @StateObject private var nightModeViewModel: NightModeViewModel
    @StateObject private var restViewModel: RestInfoViewModel
    private let viewFactory: RouteViewFactory
    private let fetchRestTimeUseCase: FetchRestTimeUseCase
    private let calculateStatsUseCase: CalculateStatsUseCase
    private let restSessionManager: RestSessionManager
    private let notificationManager: NotificationManager

    /// Initializes the coordinator with all required dependencies.
    /// - Parameter dependencies: The container providing all use cases and managers.
    init(dependencies: AppDependencies) {
        _router = StateObject(wrappedValue: Router())
        _nightModeViewModel = StateObject(wrappedValue: NightModeViewModel(
            fetchRestTimeUseCase: dependencies.fetchRestTimeUseCase,
            startRestSessionUseCase: dependencies.startRestSessionUseCase,
            completeRestSessionUseCase: dependencies.completeRestSessionUseCase,
            fetchCurrentSessionUseCase: dependencies.fetchCurrentSessionUseCase,
            restSessionManager: dependencies.restSessionManager,
            notificationManager: dependencies.notificationManager
        ))
        _restViewModel = StateObject(wrappedValue: RestInfoViewModel(
            fetchRestTimeUseCase: dependencies.fetchRestTimeUseCase,
            calculateStatsUseCase: dependencies.calculateStatsUseCase
        ))
        self.viewFactory = RouteViewFactory(dependencies: dependencies)
        self.fetchRestTimeUseCase = dependencies.fetchRestTimeUseCase
        self.calculateStatsUseCase = dependencies.calculateStatsUseCase
        self.restSessionManager = dependencies.restSessionManager
        self.notificationManager = dependencies.notificationManager
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
        .sheet(item: $router.breakBlockMode, onDismiss: {
            nightModeViewModel.reload()
            restViewModel.reload()
        }) { mode in
            NavigationStack {
                switch mode {
                case .countdown:
                    viewFactory.view(for: .breakBlock)
                case .celebration:
                    viewFactory.view(for: .breakBlockCelebrarion)
                }
            }
            .environmentObject(router)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            notificationManager.requestAuthorization { _ in }
            restSessionManager.prepareAuthorization()
            checkInitialConfiguration()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            nightModeViewModel.reload()
            restViewModel.reload()
        }
    }

    /// Checks if the user has an initial rest configuration.
    ///
    /// If no configuration exists, presents the mandatory setup screen.
    /// This ensures the user cannot use the app without setting up rest times.
    private func checkInitialConfiguration() {
        if fetchRestTimeUseCase.execute() == nil {
            router.presentRestConfiguration(mode: .mandatory)
        }
    }
}
