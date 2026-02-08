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
/// The factory is used by AppCoordinator to create views:
/// ```swift
/// let factory = RouteViewFactory(dependencies: dependencies)
/// let view = factory.view(for: .home)
/// ```
struct RouteViewFactory {

    let dependencies: AppDependencies

    // MARK: - Navigation routes

    @ViewBuilder
    func view(for route: Route) -> some View {
        switch route {

        case .home:
            // HomeScreen(
            //     viewModel: HomeViewModel(
            //         startRestUseCase: dependencies.startRestUseCase,
            //         router: dependencies.router
            //     )
            // )
            Text("Home Screen")

        case .stats:
            // StatsScreen(
            //     viewModel: StatsViewModel(
            //         calculateStatsUseCase: dependencies.calculateStatsUseCase
            //     )
            // )
            Text("Stats Screen")
        }
    }

    // MARK: - Modals

    @ViewBuilder
    func restConfigurationView(mode: RestConfigurationMode) -> some View {

        Text("Rest Configuration Modal")
    }
}

