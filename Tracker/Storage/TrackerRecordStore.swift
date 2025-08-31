import UIKit

final class TrackerRecordStore {
    private(set) var completedTrackers: [TrackerRecord] = []

    func addRecord(for trackerId: UUID, date: Date) {
        let record = TrackerRecord(trackerId: trackerId, date: date)
        completedTrackers.append(record)
        print("✅ Выполнен трекер \(trackerId) на дату \(date)")
    }

    func removeRecord(for trackerId: UUID, date: Date) {
        completedTrackers.removeAll {
            $0.trackerId == trackerId &&
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
        print("❌ Удалена отметка выполнения трекера \(trackerId) на дату \(date)")
    }

    func isCompleted(trackerId: UUID, date: Date) -> Bool {
        completedTrackers.contains {
            $0.trackerId == trackerId &&
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }
}
