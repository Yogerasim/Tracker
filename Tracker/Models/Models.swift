import Foundation

struct Tracker {
    let id: UUID
    let name: String
    let color: String
    let emoji: String
    let schedule: [WeekDay]
    let trackerCategory: TrackerCategoryCoreData?
}

enum WeekDay: Int, CaseIterable, Codable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday
    
    static func from(date: Date, calendar: Calendar = .current) -> WeekDay {

        let weekday = calendar.component(.weekday, from: date)
        
        if weekday == 1 {
            return .sunday
        }
        
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
