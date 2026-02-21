import Foundation

struct TimeToRestDTO: Codable {
    let id: UUID
    let startTime: DateComponents
    let endTime: DateComponents
    let createdAt: Date

    init(
        id: UUID,
        startTime: DateComponents,
        endTime: DateComponents,
        createdAt: Date
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.createdAt = createdAt
    }

    init(entity: TimeToRestEntity) {
        self.init(
            id: entity.id,
            startTime: entity.startTime,
            endTime: entity.endTime,
            createdAt: entity.createdAt
        )
    }

    func toEntity() -> TimeToRestEntity {
        TimeToRestEntity(
            id: id,
            startTime: startTime,
            endTime: endTime,
            createdAt: createdAt
        )
    }
}
