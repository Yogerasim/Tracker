import Foundation

final class TrackersDateFilter {
    private let calendar: Calendar
    
    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }
    
    func filterTrackers(
        _ trackers: [Tracker],
        selectedFilterIndex: Int,
        currentDate: Date,
        searchText: String,
        completionChecker: (Tracker, Date) -> Bool
    ) -> [Tracker] {
        let normalized = Calendar.current.startOfDay(for: currentDate)
        
        let text = searchText.lowercased()
        let searchFiltered = trackers.filter {
            text.isEmpty || $0.name.lowercased().contains(text)
        }
        
        switch selectedFilterIndex {
        case 1:
            let weekdayInt = Calendar.current.component(.weekday, from: normalized)
            guard let weekday = WeekDay(rawValue: weekdayInt) else { return [] }
            
            return searchFiltered.filter {
                $0.schedule.contains(weekday)
            }
        case 2:
            return searchFiltered.filter { completionChecker($0, normalized) }
        case 3:
            return searchFiltered.filter { !completionChecker($0, normalized) }
        default:
            return searchFiltered
        }
    }
}
