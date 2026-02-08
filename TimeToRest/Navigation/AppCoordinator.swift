import SwiftUI

// MARK: - AppCoordinator
/// The root view that orchestrates navigation for the application.
///
/// AppCoordinator serves as the entry point for the view hierarchy and:
/// - Sets up the NavigationStack with the Router
/// - Creates and manages the RouteViewFactory
/// - Provides the Router as an environment object to child views
/// - Defines the navigation destination mapping
///
/// ## Architecture
/// The coordinator pattern separates navigation logic from individual views,
/// making it easier to manage complex navigation flows and test navigation behavior.
///
/// ## Usage
/// AppCoordinator is instantiated in the App struct:
/// ```swift
/// @main
/// struct MyApp: App {
///     private let dependencies = AppDependencies()
///     
///     var body: some Scene {
///         WindowGroup {
///             AppCoordinator(dependencies: dependencies)
///         }
///     }
/// }
/// ```
struct AppCoordinator: View {

    @StateObject private var router: Router
    private let viewFactory: RouteViewFactory
    private let timeToRestRepository: TimeToRestRepositoryContract

    init(dependencies: AppDependencies) {
        _router = StateObject(wrappedValue: Router())
        self.viewFactory = RouteViewFactory(dependencies: dependencies)
        self.timeToRestRepository = dependencies.timeToRestRepository
    }

    var body: some View {
        NavigationStack(path: $router.navigationPath) {
            viewFactory.view(for: .home)
                .navigationDestination(for: Route.self) { route in
                    viewFactory.view(for: route)
                }
        }
        .environmentObject(router)
        .sheet(
            item: $router.restConfigurationMode,
            content: { mode in
                viewFactory.restConfigurationView(mode: mode)
            }
        )
        .onAppear {
            checkInitialConfiguration()
        }
    }

    private func checkInitialConfiguration() {
        let config = timeToRestRepository.fetch()

        if config.isEnabled == false {
            router.presentRestConfiguration(mode: .mandatory)
        }
    }
}

