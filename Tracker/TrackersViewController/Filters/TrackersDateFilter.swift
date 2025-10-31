import Foundation
final class TrackersDateFilter {
    private let calendar: Calendar
    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }
    func filterTrackersByDay(_ trackers: [Tracker], date: Date) -> [Tracker] {
        let weekday = calendar.component(.weekday, from: date)
        let adjusted = weekday == 1 ? 7 : weekday - 1
        guard let weekDay = WeekDay(rawValue: adjusted) else { return [] }
        let result = trackers.filter { $0.schedule.contains(weekDay) }
        AppLogger.trackers.debug("[DateFilter] \(result.count)/\(trackers.count) trackers match weekday \(weekDay)")
        return result
    }
    func filterTrackersByIndex(
        _ trackers: [Tracker],
        selectedFilterIndex: Int,
        currentDate: Date,
        searchText: String,
        completionChecker: (Tracker, Date) -> Bool
    ) -> [Tracker] {
        let normalized = calendar.startOfDay(for: currentDate)
        let text = searchText.lowercased()
        let searchFiltered = trackers.filter { text.isEmpty || $0.name.lowercased().contains(text) }
        var result: [Tracker]
        switch selectedFilterIndex {
        case 1: result = searchFiltered
        case 2: result = searchFiltered.filter { completionChecker($0, normalized) }
        case 3: result = searchFiltered.filter { !completionChecker($0, normalized) }
        default: result = searchFiltered
        }
        AppLogger.trackers.debug("[DateFilter] After index=\(selectedFilterIndex): \(result.count)/\(trackers.count)")
        return result
    }
}
