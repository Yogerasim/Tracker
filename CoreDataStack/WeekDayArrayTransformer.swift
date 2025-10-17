import Foundation
import CoreData

final class WeekDayArrayTransformer: ValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        NSData.self
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let weekdays = value as? [WeekDay] else { return nil }
        let rawValues = weekdays.map { $0.rawValue }
        return try? NSKeyedArchiver.archivedData(withRootObject: rawValues, requiringSecureCoding: true)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard
            let data = value as? Data,
            let rawValues = try? NSKeyedUnarchiver.unarchivedObject(
                ofClasses: [NSArray.self, NSNumber.self],
                from: data
            ) as? [Int]
        else {
            return nil
        }
        return rawValues.map { WeekDay(rawValue: $0)! }
    }
}
