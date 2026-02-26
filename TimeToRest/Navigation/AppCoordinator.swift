import SwiftUI

// MARK: - AppCoordinator
/// The root view that orchestrates navigation for the application.
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
        .sheet(
            isPresented: $router.isBreakBlockPresented,
            onDismiss: {
                nightModeViewModel.reload()
                restViewModel.reload()
            }
        ) {
            NavigationStack {
                viewFactory.view(for: .breakBlock)
                    .environmentObject(router)
            }
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

    private func checkInitialConfiguration() {
        if fetchRestTimeUseCase.execute() == nil {
            router.presentRestConfiguration(mode: .mandatory)
        }
    }
}
