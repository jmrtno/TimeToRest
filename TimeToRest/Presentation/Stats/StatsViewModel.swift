import Foundation
import Combine

// MARK: - StatsViewModel
/// ViewModel for the statistics screen.
/// Loads and exposes rest statistics for display.
@MainActor
final class StatsViewModel: ObservableObject {

    // MARK: - Published state
    @Published var stats: RestStatsEntity = .empty

    // MARK: - Dependencies
    private let calculateStatsUseCase: CalculateStatsUseCase

    init(calculateStatsUseCase: CalculateStatsUseCase) {
        self.calculateStatsUseCase = calculateStatsUseCase
    }

    // MARK: - Actions

    func onAppear() {
        loadStats()
    }

    func loadStats() {
        stats = calculateStatsUseCase.execute()
    }
}
