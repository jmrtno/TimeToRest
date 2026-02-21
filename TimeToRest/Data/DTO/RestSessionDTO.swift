import Foundation

struct RestSessionDTO: Codable {
    let id: UUID
    let day: Date
    let startedAt: Date
    let didBreakRest: Bool
    let breakReason: String?
    let brokenAt: Date?
    let isCompleted: Bool
    let avoidedMinutes: Int

    init(
        id: UUID,
        day: Date,
        startedAt: Date,
        didBreakRest: Bool,
        breakReason: String?,
        brokenAt: Date?,
        isCompleted: Bool,
        avoidedMinutes: Int
    ) {
        self.id = id
        self.day = day
        self.startedAt = startedAt
        self.didBreakRest = didBreakRest
        self.breakReason = breakReason
        self.brokenAt = brokenAt
        self.isCompleted = isCompleted
        self.avoidedMinutes = avoidedMinutes
    }

    init(entity: RestSessionEntity) {
        self.init(
            id: entity.id,
            day: entity.day,
            startedAt: entity.startedAt,
            didBreakRest: entity.didBreakRest,
            breakReason: entity.breakReason?.rawValue,
            brokenAt: entity.brokenAt,
            isCompleted: entity.isCompleted,
            avoidedMinutes: entity.avoidedMinutes
        )
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        day = try container.decode(Date.self, forKey: .day)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        didBreakRest = try container.decode(Bool.self, forKey: .didBreakRest)
        breakReason = try container.decodeIfPresent(String.self, forKey: .breakReason)
        brokenAt = try container.decodeIfPresent(Date.self, forKey: .brokenAt)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        avoidedMinutes = try container.decode(Int.self, forKey: .avoidedMinutes)
    }

    func toEntity() -> RestSessionEntity {
        RestSessionEntity(
            id: id,
            day: day,
            startedAt: startedAt,
            didBreakRest: didBreakRest,
            breakReason: breakReason.flatMap { RestSessionEntity.BreakReason(rawValue: $0) },
            brokenAt: brokenAt,
            isCompleted: isCompleted,
            avoidedMinutes: avoidedMinutes,
            startTime: DateComponents(hour: 23, minute: 30), // Default values
            endTime: DateComponents(hour: 7, minute: 0),    // Default values
            createdAt: Date()
        )
    }
}
