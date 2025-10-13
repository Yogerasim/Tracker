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

    /// Конвертация Date -> WeekDay, неделя начинается с понедельника
    static func from(date: Date, calendar: Calendar = .current) -> WeekDay {
        var cal = calendar
        cal.firstWeekday = 2 // 1 = Sunday, 2 = Monday

        let weekday = cal.component(.weekday, from: date)
        // weekday: 1 = Monday, 2 = Tuesday ... 7 = Sunday
        switch weekday {
        case 1: return .monday
        case 2: return .tuesday
        case 3: return .wednesday
        case 4: return .thursday
        case 5: return .friday
        case 6: return .saturday
        case 7: return .sunday
        default: return .monday
        }
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
