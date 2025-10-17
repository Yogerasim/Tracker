import Foundation

extension Array where Element == WeekDay {
    var descriptionText: String {
        if self.count == WeekDay.allCases.count {
            return NSLocalizedString("every_day", comment: "Каждый день / Every day")
        } else if self.isEmpty {
            return NSLocalizedString("new_habit.schedule_not_selected", comment: "Не выбрано / Not selected")
        } else {
            return self.map { $0.shortName }.joined(separator: ", ")
        }
    }
}
