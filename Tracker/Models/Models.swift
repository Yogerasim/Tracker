import Foundation

struct Tracker {
    let id: UUID
    let name: String
    let color: String
    let emoji: String
    let schedule: [WeekDay]
    let trackerCategory: TrackerCategoryCoreData? // <- Core Data тип
}

enum WeekDay: Int, CaseIterable, Codable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday

    /// Конвертация Date -> WeekDay
    static func from(date: Date, calendar: Calendar = .current) -> WeekDay {
        // Calendar.component(.weekday) возвращает 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        let weekday = calendar.component(.weekday, from: date)

        // Если weekday == 1 -> Sunday (в enum .sunday == 7)
        if weekday == 1 {
            return .sunday
        }

        // Иначе weekday 2..7 -> Monday..Saturday, соответствуют rawValue 1..6
        return WeekDay(rawValue: weekday - 1) ?? .monday
    }
}

struct TrackerCategory {
    let id: UUID
    let title: String
    let trackers: [Tracker]
}

struct TrackerRecord {
    let trackerId: UUID
    let date: Date
}
