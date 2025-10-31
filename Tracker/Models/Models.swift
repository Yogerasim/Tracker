import Foundation
struct Tracker {
    let id: UUID
    let name: String
    let color: String
    let emoji: String
    let schedule: [WeekDay]
    let trackerCategory: TrackerCategoryCoreData?
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
