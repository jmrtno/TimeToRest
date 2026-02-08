import Foundation
import Combine

// MARK: - AppDependencies
/// A container that manages the creation and lifecycle of all application dependencies.
///
/// AppDependencies serves as the composition root for dependency injection.
/// It creates and wires together repositories, services, and use cases,
/// ensuring proper dependency graphs and lazy initialization.
///
/// ## Design Principles
/// - **Lazy Initialization**: Dependencies are created only when first accessed
/// - **Single Source of Truth**: One place for all dependency creation
/// - **Proper Layering**: Data layer → Domain layer → Presentation layer
/// - **Testability**: Can be subclassed or replaced for testing
///
/// ## Usage
/// ```swift
/// let dependencies = AppDependencies()
/// let viewModel = SomeViewModel(useCase: dependencies.someUseCase)
/// ```
final class AppDependencies {

    // MARK: - Data layer (Repositories)

    lazy var timeToRestRepository: TimeToRestRepositoryContract = {
        TimeToRestRepository()
    }()

    lazy var restSessionRepository: RestSessionRepositoryContract = {
        RestSessionRepository()
    }()

    lazy var notificationManager: NotificationManager = {
        NotificationManager()
    }()

    // MARK: - Use Cases (TimeToRest configuration)

    lazy var fetchRestTimeUseCase: FetchRestTimeUseCase = {
        FetchRestTimeUseCase(repository: timeToRestRepository)
    }()

    lazy var createRestTimeUseCase: CreateRestTimeUseCase = {
        CreateRestTimeUseCase(repository: timeToRestRepository)
    }()

    lazy var updateRestTimeUseCase: UpdateRestTimeUseCase = {
        UpdateRestTimeUseCase(repository: timeToRestRepository)
    }()

    // MARK: - Use Cases (Rest sessions)

    lazy var startRestSessionUseCase: StartRestSessionUseCase = {
        StartRestSessionUseCase(
            sessionRepository: restSessionRepository,
            configRepository: timeToRestRepository
        )
    }()

    lazy var breakRestUseCase: BreakRestUseCase = {
        BreakRestUseCase(
            repository: restSessionRepository
        )
    }()

    lazy var calculateStatsUseCase: CalculateStatsUseCase = {
        CalculateStatsUseCase(
            repository: restSessionRepository
        )
    }()
}
