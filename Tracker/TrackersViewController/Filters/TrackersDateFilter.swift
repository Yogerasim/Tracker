import Foundation

final class TrackersDateFilter {
    private let calendar: Calendar
    
    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }
    
    
    func filterTrackersByDay(_ trackers: [Tracker], date: Date) -> [Tracker] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let adjusted = weekday == 1 ? 7 : weekday - 1
        guard let weekDay = WeekDay(rawValue: adjusted) else { return [] }

        print("📅 [DateFilter] Фильтруем трекеры для дня: \(weekDay) (\(date))")
        
        for tracker in trackers {
            let scheduleString = tracker.schedule.map { $0.shortName }.joined(separator: ", ")
            print("    🔹 Трекер: \(tracker.name), schedule: [\(scheduleString)]")
        }

        let filtered = trackers.filter { tracker in
            let contains = tracker.schedule.contains(weekDay)
            print("        -> \(tracker.name) \(contains ? "✅" : "❌") подходит для \(weekDay)")
            return contains
        }

        print("📊 [DateFilter] Всего трекеров после фильтрации: \(filtered.count)")
        return filtered
    }
    
    // Фильтрация по индексу фильтра
    func filterTrackersByIndex(
        _ trackers: [Tracker],
        selectedFilterIndex: Int,
        currentDate: Date,
        searchText: String,
        completionChecker: (Tracker, Date) -> Bool
    ) -> [Tracker] {
        let normalized = calendar.startOfDay(for: currentDate)
        let text = searchText.lowercased()
        let searchFiltered = trackers.filter {
            text.isEmpty || $0.name.lowercased().contains(text)
        }
        
        switch selectedFilterIndex {
        case 1: // Today
            let weekdayInt = calendar.component(.weekday, from: normalized)
            guard let weekday = WeekDay(rawValue: weekdayInt) else { return [] }
            return searchFiltered.filter { $0.schedule.contains(weekday) }
        case 2: // Completed
            return searchFiltered.filter { completionChecker($0, normalized) }
        case 3: // Not completed
            return searchFiltered.filter { !completionChecker($0, normalized) }
        default: // All
            return searchFiltered
        }
    }
}
