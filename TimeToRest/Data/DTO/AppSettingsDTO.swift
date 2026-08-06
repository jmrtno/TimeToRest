import Foundation

struct AppSettingsDTO: Codable {
    let id: UUID
    let gracePeriodMinutes: Int
    let isNotificationsEnabled: Bool

    init(
        id: UUID,
        gracePeriodMinutes: Int,
        isNotificationsEnabled: Bool
    ) {
        self.id = id
        self.gracePeriodMinutes = gracePeriodMinutes
        self.isNotificationsEnabled = isNotificationsEnabled
    }

    init(entity: AppSettingsEntity) {
        self.init(
            id: entity.id,
            gracePeriodMinutes: entity.gracePeriodMinutes,
            isNotificationsEnabled: entity.isNotificationsEnabled
        )
    }

    func toEntity() -> AppSettingsEntity {
        AppSettingsEntity(
            id: id,
            gracePeriodMinutes: gracePeriodMinutes,
            isNotificationsEnabled: isNotificationsEnabled
        )
    }
}
