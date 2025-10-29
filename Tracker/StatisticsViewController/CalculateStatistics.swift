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
        guard !records.isEmpty else {
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
        for (_, dailyRecords) in recordsByDay {
            if dailyRecords.count == allTrackersCount {
                idealDaysCount += 1
            }
        }
        return Statistics(
            bestPeriod: bestStreak,
            idealDays: idealDaysCount,
            completedTrackers: totalCompleted,
            averageTrackersPerDay: average
        )
    }
}
