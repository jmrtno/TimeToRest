import Foundation

// MARK: - BreakBlockMode
/// Represents the different modes for the break block modal.
///
/// - `celebration`: Shown when the user successfully completes a rest session.
/// - `countdown`: Shown when the user attempts to break the rest, displaying a countdown.
enum BreakBlockMode: Identifiable, Sendable {
    /// Modal displayed after a successful rest completion.
    case celebration
    /// Modal displayed with a countdown when the user tries to break the rest.
    case countdown
    /// Conforms to `Identifiable` to be used with SwiftUI's `sheet(item:)`.
    var id: Self { self }
}
