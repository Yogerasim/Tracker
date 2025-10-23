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
        let normalized = currentDate.startOfDayUTC()
        
        let text = searchText.lowercased()
        let searchFiltered = trackers.filter {
            text.isEmpty || $0.name.lowercased().contains(text)
        }
        
        switch selectedFilterIndex {
        case 1:
            // На сегодня
            return searchFiltered.filter {
                let passes = $0.schedule.contains(normalized.weekDay)
                print("   ◼️ [DateFilter] \($0.name) schedule passes: \(passes)")
                return passes
            }
            
        case 2:
            // Завершённые
            return searchFiltered.filter {
                let completed = completionChecker($0, normalized)
                print("   ✅ [DateFilter] \($0.name) completed on \(normalized): \(completed)")
                return completed
            }
            
        case 3:
            // Незавершённые
            return searchFiltered.filter {
                let completed = completionChecker($0, normalized)
                print("   ❌ [DateFilter] \($0.name) completed on \(normalized): \(completed) → include = \(!completed)")
                return !completed
            }
            
        default:
            return searchFiltered
        }
    }
}
