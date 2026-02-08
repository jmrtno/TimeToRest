import Foundation

struct BreakRestUseCase {
    private let repository: RestSessionRepositoryContract

    init(repository: RestSessionRepositoryContract) {
        self.repository = repository
    }

    /// Rompe la sesión actual
    func execute(session: RestSessionEntity, breakedAt: Date = Date()) -> RestSessionEntity {
        // Calcula minutos evitados hasta romper
        let avoidedMinutes = max(0, Int(breakedAt.timeIntervalSince(session.startedAt) / 60))

        // Crea una nueva sesión con didBreakRest = true
        let updatedSession = RestSessionEntity(
            id: session.id,
            day: session.day,
            startedAt: session.startedAt,
            delayInMinutes: session.delayInMinutes,
            didBreakRest: true,
            breakedAt: breakedAt,
            avoidedMinutes: avoidedMinutes
        )

        // Guarda la sesión actualizada
        repository.update(updatedSession)

        return updatedSession
    }
}
