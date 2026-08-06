import Foundation

// MARK: - NightModeViewModel+WindowCalculation
extension NightModeViewModel {

    // MARK: - Night Window Logic

    static func isCurrentlyInNightWindow(config: TimeToRestEntity, now: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotal = currentHour * 60 + currentMinute

        let startHour = config.startTime.hour ?? 23
        let startMinute = config.startTime.minute ?? 30
        let startTotal = startHour * 60 + startMinute

        let endHour = config.endTime.hour ?? 7
        let endMinute = config.endTime.minute ?? 0
        let endTotal = endHour * 60 + endMinute

        if startTotal > endTotal {
            return currentTotal >= startTotal || currentTotal < endTotal
        } else {
            return currentTotal >= startTotal && currentTotal < endTotal
        }
    }

    // MARK: - Helpers

    func configuredWindowMinutes() -> Int {
        let startTotal = (config.startTime.hour ?? 23) * 60 + (config.startTime.minute ?? 30)
        let endTotal = (config.endTime.hour ?? 7) * 60 + (config.endTime.minute ?? 0)
        return endTotal >= startTotal ? (endTotal - startTotal) : (24 * 60 - startTotal + endTotal)
    }

    func sessionRestMinutes(session: RestSessionEntity) -> Int {
        let calendar = Calendar.current
        let normalizedStart = calendar.date(
            from: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: session.startedAt)
        ) ?? session.startedAt

        var endComponents = calendar.dateComponents([.year, .month, .day], from: normalizedStart)
        endComponents.hour = config.endTime.hour ?? 7
        endComponents.minute = config.endTime.minute ?? 0
        endComponents.second = 0

        guard var endDate = calendar.date(from: endComponents) else {
            return configuredWindowMinutes()
        }

        if endDate <= normalizedStart {
            endDate = calendar.date(byAdding: .day, value: 1, to: endDate) ?? endDate
        }

        return max(0, Int(endDate.timeIntervalSince(normalizedStart) / 60))
    }
}
