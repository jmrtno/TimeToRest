import SwiftUI

// MARK: - RouteViewFactory
/// A factory that creates views for each route with their required dependencies.
///
/// RouteViewFactory centralizes view instantiation and dependency injection,
/// keeping the navigation layer clean and testable. It receives the AppDependencies
/// container and uses it to construct ViewModels with their required use cases.
///
/// ## Responsibilities
/// - Map routes to their corresponding views
/// - Instantiate ViewModels with proper dependencies
/// - Keep view creation logic in one place
///
/// ## Usage
/// The factory is used by AppCoordinator to create pushed views:
/// ```swift
/// let factory = RouteViewFactory(dependencies: dependencies)
/// let view = factory.view(for: .breakBlock)
/// ```
struct RouteViewFactory {

    let dependencies: AppDependencies

    // MARK: - Navigation routes

    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {

        case .breakBlock:
            BreakBlockScreen(
                viewModel: BreakBlockViewModel(
                    calculateStatsUseCase: dependencies.calculateStatsUseCase,
                    restSessionManager: dependencies.restSessionManager,
                    isStrictMode: dependencies.fetchRestTimeUseCase.execute()?.isStrictModeEnabled ?? false
                )
            )
        }
    }

    // MARK: - Modals

    @ViewBuilder
    func restConfigurationView(mode: RestConfigurationMode) -> some View {
        NavigationStack {
            SetupScreen(
                viewModel: SetupViewModel(
                    mode: mode,
                    saveRestTimeUseCase: dependencies.saveRestTimeUseCase,
                    fetchRestTimeUseCase: dependencies.fetchRestTimeUseCase,
                    notificationManager: dependencies.notificationManager,
                    restSessionManager: dependencies.restSessionManager
                )
            )
        }
    }
}
