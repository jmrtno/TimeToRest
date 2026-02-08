import Foundation

/// Represents the result of a night according to the user's decision
enum RestDayResult: String, Codable {
    case completed
    case broken
    case notStarted
}
