import Foundation
import Combine

// MARK: - RestInfoViewModel
/// ViewModel for the Rest (day) view.
/// Handles configuration/stats displayed on RestView.
@MainActor
final class RestInfoViewModel: ObservableObject {

    // MARK: - Published state
    @Published var config: TimeToRestEntity = .firstConfig
    @Published var stats: RestStatsEntity = .empty
    @Published var hasConfiguration: Bool = false
    @Published var isPressed: Bool = false

    // MARK: - Dependencies
    private let fetchRestTimeUseCase: FetchRestTimeUseCase
    private let calculateStatsUseCase: CalculateStatsUseCase

    init(
        fetchRestTimeUseCase: FetchRestTimeUseCase,
        calculateStatsUseCase: CalculateStatsUseCase
    ) {
        self.fetchRestTimeUseCase = fetchRestTimeUseCase
        self.calculateStatsUseCase = calculateStatsUseCase
    }

    // MARK: - Lifecycle

    func onAppear() {
        reload()
    }

    func reload() {
        guard loadConfig() else { return }
        loadStats()
    }

    func reloadAfterConfigChange() {
        guard loadConfig() else { return }
        loadStats()
    }

    // MARK: - Data loading

    @discardableResult
    func loadConfig() -> Bool {
        guard let fetched = fetchRestTimeUseCase.execute() else {
            hasConfiguration = false
            return false
        }
        hasConfiguration = true
        config = fetched
        return true
    }

    func loadStats() {
        stats = calculateStatsUseCase.execute()

#if DEBUG
        stats = .debugConsistentMock()
#endif
    }

    // MARK: - UI helpers

    var formattedStartTime: String {
        let h = config.startTime.hour ?? 23
        let m = config.startTime.minute ?? 30
        return String(format: "%02d:%02d", h, m)
    }

    var formattedEndTime: String {
        let h = config.endTime.hour ?? 7
        let m = config.endTime.minute ?? 0
        return String(format: "%02d:%02d", h, m)
    }
}

// MARK: - Preview

#if DEBUG
extension RestInfoViewModel {

    static var preview: RestInfoViewModel {
        struct MockTimeRepo: TimeToRestRepositoryContract {
            func hasConfiguration() -> Bool { true }
            func fetch() -> TimeToRestEntity { .firstConfig }
            func save(_ restTime: TimeToRestEntity) async {}
            func update(_ restTime: TimeToRestEntity) async {}
        }
        struct MockSessionRepo: RestSessionRepositoryContract {
            func fetchAll() -> [RestSessionEntity] { [] }
            func fetch(for day: Date) -> RestSessionEntity? { nil }
            func save(_ session: RestSessionEntity) async {}
            func update(_ session: RestSessionEntity) async {}
        }
        return RestInfoViewModel(
            fetchRestTimeUseCase: FetchRestTimeUseCase(repository: MockTimeRepo()),
            calculateStatsUseCase: CalculateStatsUseCase(repository: MockSessionRepo())
        )
    }
}
#endif
