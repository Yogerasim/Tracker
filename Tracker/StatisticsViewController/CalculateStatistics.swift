import CoreData
import Foundation

final class CalculateStatistics {
    private let trackerRecordStore: TrackerRecordStore

    init(trackerRecordStore: TrackerRecordStore) {
        self.trackerRecordStore = trackerRecordStore
    }

    struct Statistics {
        let bestPeriod: Int
        let idealDays: Int
        let completedTrackers: Int
        let averageTrackersPerDay: Int
    }

    func calculateStatistics() -> Statistics {
        let records = trackerRecordStore.fetchAllRecords().sorted { $0.date < $1.date }
        AppLogger.trackers.info("[Stats] Всего записей: \(records.count)")

        guard !records.isEmpty else {
            AppLogger.trackers.info("[Stats] Нет записей — возвращаю нули")
            return Statistics(bestPeriod: 0, idealDays: 0, completedTrackers: 0, averageTrackersPerDay: 0)
        }

        var bestStreak = 1
        var currentStreak = 1

        for i in 1 ..< records.count {
            let prev = records[i - 1].date.startOfDayUTC()
            let curr = records[i].date.startOfDayUTC()
            let dayDiff = Calendar(identifier: .gregorian)
                .dateComponents([.day], from: prev, to: curr).day ?? 0

            if dayDiff == 1 {
                currentStreak += 1
            } else if dayDiff == 0 {
                continue
            } else {
                currentStreak = 1
            }
            bestStreak = max(bestStreak, currentStreak)
        }

        let totalCompleted = records.count
        let days = Set(records.map { $0.date.startOfDayUTC() }).count
        let average = days > 0 ? totalCompleted / days : 0
        let allTrackersCount = trackerRecordStore.fetchAllTrackersCount()

        var idealDaysCount = 0
        let recordsByDay = Dictionary(grouping: records) { $0.date.startOfDayUTC() }

        for (date, dailyRecords) in recordsByDay {
            let isIdeal = dailyRecords.count == allTrackersCount
            if isIdeal {
                idealDaysCount += 1
            }
            AppLogger.trackers.info("[Stats] День \(date.formatted()) — завершено: \(dailyRecords.count) из \(allTrackersCount)")
        }

        AppLogger.trackers.info("""
        [Stats] === Результаты ===
        ✅ Лучший период: \(bestStreak)
        🌕 Идеальных дней: \(idealDaysCount)
        🟩 Завершено трекеров: \(totalCompleted)
        📊 Среднее в день: \(average)
        =========================
        """)

        return Statistics(
            bestPeriod: bestStreak,
            idealDays: idealDaysCount,
            completedTrackers: totalCompleted,
            averageTrackersPerDay: average
        )
    }
}
