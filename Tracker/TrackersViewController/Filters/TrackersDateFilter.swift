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
        
        // Поиск
        let searchFiltered = trackers.filter {
            text.isEmpty || $0.name.lowercased().contains(text)
        }
        
        // Основные фильтры
        switch selectedFilterIndex {
        case 0:
            return searchFiltered
        case 1:
            return searchFiltered.filter {
                $0.schedule.contains(currentDate.weekDay)
            }
        case 2:
            return searchFiltered.filter {
                completionChecker($0, currentDate)
            }
        case 3:
            return searchFiltered.filter {
                !completionChecker($0, currentDate)
            }
        default:
            return searchFiltered
        }
    }
}
