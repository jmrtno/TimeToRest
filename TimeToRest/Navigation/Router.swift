import SwiftUI

// MARK: - RestConfigurationDismissReason
/// Describes how the rest configuration modal was dismissed, so the
/// coordinator can decide whether to restart the rest session.
enum RestConfigurationDismissReason {
    /// The user cancelled without saving.
    case cancelled
    /// The user pressed Save but the night schedule did not change.
    case savedWithoutChanges
    /// The user pressed Save and the night schedule changed.
    case savedWithChanges
}

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
/// - Observable for reactive UI updates (Swift 6 @Observable)
///
/// ## Usage
/// The Router is typically injected as an environment value:
/// ```swift
/// @Environment(Router.self) private var router
///
/// func navigateToDetail() {
///     router.push(.detail)
/// }
/// ```
@MainActor
@Observable
final class Router {
    /// The navigation path for the main NavigationStack.
    var path = NavigationPath()
    /// The currently presented break block modal mode, if any.
    var breakBlockMode: BreakBlockMode?

    // MARK: - Modal state
    /// The currently presented rest configuration modal mode, if any.
    var restConfigurationMode: RestConfigurationMode?

    /// How the rest configuration modal was dismissed, consumed by the
    /// sheet's onDismiss handler.
    private var restConfigurationDismissReason: RestConfigurationDismissReason?

    /// Pushes a new route onto the navigation stack.
    /// - Parameter route: The route to navigate to
    func push(_ route: Route) {
        path.append(route)
    }

    /// Pops the top route from the navigation stack.
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// Pops all routes and returns to the root view.
    func popToRoot() {
        dismissBreakBlock()
        path = NavigationPath()
    }

    // MARK: - Modal control
    func presentRestConfiguration(mode: RestConfigurationMode) {
        restConfigurationDismissReason = nil
        restConfigurationMode = mode
    }

    func dismissRestConfiguration(reason: RestConfigurationDismissReason) {
        restConfigurationDismissReason = reason
        restConfigurationMode = nil
    }

    /// Reads and clears the dismiss reason of the last rest configuration presentation.
    func consumeRestConfigurationDismissReason() -> RestConfigurationDismissReason {
        let reason = restConfigurationDismissReason ?? .cancelled
        restConfigurationDismissReason = nil
        return reason
    }
    
    func presentBreakBlock(mode: BreakBlockMode) {
        breakBlockMode = mode
    }

    func dismissBreakBlock() {
        breakBlockMode = nil
    }

}
