import Foundation

// MARK: - CompleteRestSessionUseCase
/// A use case that encapsulates a single business operation.
///
/// Use cases represent the application's business rules and orchestrate the flow
/// of data between entities and repositories. They are the entry points to the
/// domain layer from the presentation layer.
///
/// ## Design Principles
/// - Single Responsibility: Each use case handles one specific business operation
/// - Dependency Injection: Repositories and services are injected via initializer
/// - Framework Independence: No UI or infrastructure dependencies
/// - Testability: Easy to unit test with mock dependencies
///
/// ## Usage
/// ```swift
/// let useCase = CompleteRestSessionUseCase(repository: repository)
/// let result = useCase.execute(parameters)
/// ```
struct CompleteRestSessionUseCase {
    private let repository: RestSessionRepositoryContract
    private let calendar = Calendar.current
    
    init(repository: RestSessionRepositoryContract) {
        self.repository = repository
    }
    
    /// Executes the use case operation.
    ///
    /// - Parameter input: The input required for this operation (modify as needed)
    /// - Returns: The result of the operation (modify return type as needed)
    /// This method is no longer used - completion is now manual only
    func execute(session: RestSessionEntity, completedAt: Date = Date()) async -> RestSessionEntity? {
        
        var components = calendar.dateComponents([.year, .month, .day], from: session.day)
        components.hour = session.endTime.hour ?? 0
        components.minute = session.endTime.minute ?? 0
        components.second = session.endTime.second ?? 0

        guard var endDate = calendar.date(from: components) else {
            return nil
        }
        if endDate <= session.startedAt {
            endDate = calendar.date(byAdding: .day, value: 1, to: endDate) ?? endDate
        }

        guard completedAt >= endDate else {
            return nil
        }
 
        let avoidedMinutes = max(0, Int(endDate.timeIntervalSince(session.startedAt) / 60))
 
        let completedSession = RestSessionEntity(
            id: session.id,
            day: session.day,
            startedAt: session.startedAt,
            didBreakRest: false,
            breakReason: nil,
            brokenAt: nil,
            isCompleted: true,
            avoidedMinutes: avoidedMinutes,
            startTime: session.startTime,
            endTime: session.endTime,
            createdAt: session.createdAt
        )
 
        await repository.update(completedSession)
        return completedSession
    }
}
