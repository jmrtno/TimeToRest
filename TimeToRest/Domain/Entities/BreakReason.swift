import Foundation

// MARK: - BreakReason
/// Represents the reason why a rest session was broken
///
/// This enum centralizes all possible break reasons across the application
/// following Clean Architecture principles. It's used by both the domain layer
/// and infrastructure layer components.
enum BreakReason: String, Equatable, CaseIterable {
    case manualCancellation
    case blockedSocialAppUsage
    
    /// Raw value for persistence and external communication
    var rawValue: String {
        switch self {
        case .manualCancellation:
            return "manual_cancellation"
        case .blockedSocialAppUsage:
            return "blocked_social_app_usage"
        }
    }
    
    /// Initialize from raw value
    init?(rawValue: String) {
        switch rawValue {
        case "manual_cancellation":
            self = .manualCancellation
        case "blocked_social_app_usage":
            self = .blockedSocialAppUsage
        default:
            return nil
        }
    }
}
