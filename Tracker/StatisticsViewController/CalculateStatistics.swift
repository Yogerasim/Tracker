import Foundation
import CoreData

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

        // MARK: - Best Period
        var bestStreak = records.isEmpty ? 0 : 1
        var currentStreak = 1
        for i in 1..<records.count {
            let prev = Calendar.current.startOfDay(for: records[i - 1].date)
            let curr = Calendar.current.startOfDay(for: records[i].date)
            if Calendar.current.dateComponents([.day], from: prev, to: curr).day == 1 {
                currentStreak += 1
            } else if Calendar.current.isDate(prev, inSameDayAs: curr) {
                continue
            } else {
                currentStreak = 1
            }
            bestStreak = max(bestStreak, currentStreak)
        }

        let totalCompleted = records.count
        let days = Set(records.map { Calendar.current.startOfDay(for: $0.date) }).count
        let average = days > 0 ? totalCompleted / days : 0

        let allTrackersCount = fetchAllTrackersCount()
        var idealDaysCount = 0
        let recordsByDay = Dictionary(grouping: records) { Calendar.current.startOfDay(for: $0.date) }
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

    private func fetchAllTrackersCount() -> Int {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        do {
            return try trackerRecordStore.viewContext.count(for: request)
        } catch {
            print("❌ Ошибка подсчета всех трекеров: \(error)")
            return 0
        }
    }
}
