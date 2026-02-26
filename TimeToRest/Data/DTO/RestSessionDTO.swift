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
    let startTime: DateComponents
    let endTime: DateComponents
    let createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case day
        case startedAt
        case didBreakRest
        case breakReason
        case brokenAt
        case isCompleted
        case avoidedMinutes
        case startTime
        case endTime
        case createdAt
    }

    init(
        id: UUID,
        day: Date,
        startedAt: Date,
        didBreakRest: Bool,
        breakReason: String?,
        brokenAt: Date?,
        isCompleted: Bool,
        avoidedMinutes: Int,
        startTime: DateComponents,
        endTime: DateComponents,
        createdAt: Date
    ) {
        self.id = id
        self.day = day
        self.startedAt = startedAt
        self.didBreakRest = didBreakRest
        self.breakReason = breakReason
        self.brokenAt = brokenAt
        self.isCompleted = isCompleted
        self.avoidedMinutes = avoidedMinutes
        self.startTime = startTime
        self.endTime = endTime
        self.createdAt = createdAt
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
            avoidedMinutes: entity.avoidedMinutes,
            startTime: entity.startTime,
            endTime: entity.endTime,
            createdAt: entity.createdAt
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
        startTime = try container.decodeIfPresent(DateComponents.self, forKey: .startTime)
        ?? DateComponents(hour: 23, minute: 30)
        endTime = try container.decodeIfPresent(DateComponents.self, forKey: .endTime)
        ?? DateComponents(hour: 7, minute: 0)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? day
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
            startTime: startTime,
            endTime: endTime,
            createdAt: createdAt
        )
    }
}
