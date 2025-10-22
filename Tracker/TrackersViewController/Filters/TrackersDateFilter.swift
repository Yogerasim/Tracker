import Foundation

final class TrackersDateFilter {
    private let recordStore: TrackerRecordStore
    private let calendar: Calendar
    
    init(recordStore: TrackerRecordStore, calendar: Calendar = .current) {
        self.recordStore = recordStore
        self.calendar = calendar
    }
    
    func filterTrackers(
        _ trackers: [Tracker],
        selectedFilterIndex: Int,
        currentDate: Date,
        searchText: String,
        completionChecker: (Tracker, Date) -> Bool
    ) -> [Tracker] {
        
        let text = searchText.lowercased()
        let searchFiltered = trackers.filter {
            text.isEmpty || $0.name.lowercased().contains(text)
        }
        
        print("🟣 [DateFilter] searchFiltered.count = \(searchFiltered.count), currentDate = \(currentDate)")
        
        switch selectedFilterIndex {
        case 0:
            // Все трекеры
            return searchFiltered
            
        case 1:
            // На сегодня
            return searchFiltered.filter {
                let passes = $0.schedule.contains(currentDate.weekDay)
                print("   ◼️ [DateFilter] \($0.name) schedule passes: \(passes)")
                return passes
            }
            
        case 2:
            // Завершенные
            return searchFiltered.filter {
                let completed = completionChecker($0, currentDate)
                print("   ✅ [DateFilter] \($0.name) completed on \(currentDate): \(completed)")
                return completed
            }
            
        case 3:
            // Незавершенные
            return searchFiltered.filter {
                let completed = completionChecker($0, currentDate)
                print("   ❌ [DateFilter] \($0.name) completed on \(currentDate): \(completed) → include = \(!completed)")
                return !completed
            }
            
        default:
            return searchFiltered
        }
    }
}
