import SwiftUI
import Combine

// MARK: - Router
/// A Router that manages the navigation stack for the application.
///
/// The Router provides a centralized way to handle navigation operations,
/// making it easy to push, pop, and replace routes in a type-safe manner.
/// It is designed to work with SwiftUI's `NavigationStack`.
///
/// ## Features
/// - Type-safe navigation using Route enum
/// - Centralized navigation state management
/// - Support for push, pop, pop-to-root, and replace operations
/// - Observable for reactive UI updates
///
/// ## Usage
/// The Router is typically injected as an environment object:
/// ```swift
/// @EnvironmentObject private var router: Router
/// 
/// func navigateToDetail() {
///     router.push(.detail)
/// }
/// ```
@MainActor
final class Router: ObservableObject {
    @Published var navigationPath: [Route] = []
    
    // MARK: - Modal state
    @Published var restConfigurationMode: RestConfigurationMode?
    
    /// Pushes a new route onto the navigation stack.
    /// - Parameter route: The route to navigate to
    func push(_ route: Route) {
        navigationPath.append(route)
    }
    
    /// Pops the top route from the navigation stack.
    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }
    
    /// Pops all routes and returns to the root view.
    func popToRoot() {
        navigationPath.removeAll()
    }
    
    /// Replaces the entire navigation stack with new routes.
    /// - Parameter routes: The new routes to set
    func replace(with routes: [Route]) {
        navigationPath = routes
    }

    // MARK: - Modal control

    // MARK: - Modal control
    func presentRestConfiguration(mode: RestConfigurationMode) {
        restConfigurationMode = mode
    }

    func dismissRestConfiguration() {
        restConfigurationMode = nil
    }
}
