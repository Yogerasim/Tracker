import Foundation

final class TrackerStore {
    // MARK: - Хранилища
    private(set) var categories: [TrackerCategory] = []
    private(set) var completedTrackers: [TrackerRecord] = []
    
    // MARK: - Методы работы с категориями
    func addCategory(_ category: TrackerCategory) {
        categories.append(category)
    }
    
    func addTracker(_ tracker: Tracker, to categoryTitle: String) {
        guard let index = categories.firstIndex(where: { $0.title == categoryTitle }) else {
            return
        }
        
        let category = categories[index]
        let newCategory = TrackerCategory(
            title: category.title,
            trackers: category.trackers + [tracker]
        )
        
        categories[index] = newCategory
    }
    
    // MARK: - Методы работы с выполненными трекерами
    func addRecord(for trackerId: UUID, date: Date) {
        let record = TrackerRecord(trackerId: trackerId, date: date)
        completedTrackers.append(record)
    }
    
    func removeRecord(for trackerId: UUID, date: Date) {
        completedTrackers.removeAll {
            $0.trackerId == trackerId &&
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }
    
    func isCompleted(trackerId: UUID, date: Date) -> Bool {
        completedTrackers.contains {
            $0.trackerId == trackerId &&
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }
}
