// MARK: - Route
/// An enum that defines all navigable destinations in the application.
///
/// Routes provide type-safe navigation and can carry associated data
/// needed for each destination. They work with the Router and
/// RouteViewFactory to enable declarative navigation.
///
/// ## Design Guidelines
/// - Add a case for each navigable screen
/// - Use associated values to pass data to destinations
/// - Implement `Hashable` for use with NavigationStack
/// - Implement `Identifiable` for list-based navigation
///
/// ## Usage
/// ```swift
/// // Navigate to a route
/// router.push(.detail(id: item.id))
/// 
/// // Define routes
/// enum Route: Hashable {
///     case list
///     case detail(id: UUID)
/// }
/// ```
enum Route: Hashable, Identifiable, Sendable {
    /// The countdown modal shown when the user attempts to break rest.
    case breakBlock
    /// The celebration modal shown after successfully completing a rest session.
    case breakBlockCelebration

    /// A unique identifier for each route case.
    ///
    /// Used by SwiftUI's `sheet(item:)` to differentiate between routes.
    var id: String {
        switch self {
        case .breakBlock:
            return "breakBlock"
        case .breakBlockCelebration:
            return "breakBlockCelebration"
        }
    }
}

