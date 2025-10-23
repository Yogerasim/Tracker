import Foundation

extension Date {
    func startOfDayUTC() -> Date {
        let calendar = Calendar(identifier: .gregorian)
        var components = calendar.dateComponents([.year, .month, .day], from: self)
        components.timeZone = TimeZone(abbreviation: "UTC")
        return calendar.date(from: components)!
    }
    
    func endOfDayUTC() -> Date {
        return Calendar(identifier: .gregorian)
            .date(byAdding: .day, value: 1, to: self.startOfDayUTC())!
    }
}
