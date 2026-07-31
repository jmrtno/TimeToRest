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

    /// The dependencies container providing all required use cases and managers.
    let dependencies: AppDependencies

    // MARK: - Navigation routes

    /// Creates a view for the given navigation route.
    /// - Parameter route: The route to create a view for.
    /// - Returns: A SwiftUI view configured for the route.
    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {
        case .breakBlock:
            BreakBlockTimerScreen(
                viewModel: makeBreakBlockViewModel()
            )
        case .breakBlockCelebration:
            BreakBlockCelebrationScreen(
                viewModel: makeBreakBlockViewModel()
            )
        }
    }

    // MARK: - Modals

    /// Creates the rest configuration modal view.
    /// - Parameter mode: The configuration mode (e.g., mandatory, optional).
    /// - Returns: A NavigationStack containing the SetupScreen.
    @ViewBuilder
    func restConfigurationView(mode: RestConfigurationMode) -> some View {
        NavigationStack {
            SetupScreen(
                viewModel: SetupViewModel(
                    mode: mode,
                    saveRestTimeUseCase: dependencies.saveRestTimeUseCase,
                    fetchRestTimeUseCase: dependencies.fetchRestTimeUseCase,
                    getSleepTipUseCase: dependencies.getSleepTipUseCase,
                    notificationManager: dependencies.notificationManager,
                    restSessionManager: dependencies.restSessionManager
                )
            )
        }
    }

    // MARK: - Helpers

    /// Creates a shared BreakBlockViewModel with required dependencies.
    /// - Returns: A new BreakBlockViewModel instance.
    private func makeBreakBlockViewModel() -> BreakBlockViewModel {
        BreakBlockViewModel(
            calculateStatsUseCase: dependencies.calculateStatsUseCase,
            restSessionManager: dependencies.restSessionManager,
            notificationManager: dependencies.notificationManager
        )
    }
}
