import Foundation
extension Array where Element == WeekDay {
    var descriptionText: String {
        if count == WeekDay.allCases.count {
            return NSLocalizedString("every_day", comment: "Каждый день / Every day")
        } else if isEmpty {
            return NSLocalizedString("new_habit.schedule_not_selected", comment: "Не выбрано / Not selected")
        } else {
            return map { $0.shortName }.joined(separator: ", ")
        }
    }
}
