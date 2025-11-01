import Foundation
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
extension WeekDay {
    var shortName: String {
        let key: String
        switch self {
        case .monday: key = "weekdays.short.monday"
        case .tuesday: key = "weekdays.short.tuesday"
        case .wednesday: key = "weekdays.short.wednesday"
        case .thursday: key = "weekdays.short.thursday"
        case .friday: key = "weekdays.short.friday"
        case .saturday: key = "weekdays.short.saturday"
        case .sunday: key = "weekdays.short.sunday"
        }
        return NSLocalizedString(key, comment: "Short name for \(self)")
    }
}
