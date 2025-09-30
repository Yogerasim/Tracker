import Foundation
import CoreData

final class TrackersViewModel {
    
    // MARK: - Stores
    private let categoryStore: TrackerCategoryStore
    private let recordStore: TrackerRecordStore
    private let trackerStore: TrackerStore
    
    // MARK: - State
    private let defaultCategoryTitle = "Мои трекеры"
    @Published private(set) var trackers: [Tracker] = []
    @Published var currentDate: Date = Date()
    @Published var categories: [TrackerCategory] = []
    @Published var completedTrackers: [TrackerRecord] = []
    
    // MARK: - Callbacks
    var onTrackersUpdated: (() -> Void)?
    var onCategoriesUpdated: (() -> Void)?
    var onDateChanged: ((Date) -> Void)?
    
    // MARK: - Init
    init(container: NSPersistentContainer = CoreDataStack.shared.persistentContainer) {
        self.categoryStore = TrackerCategoryStore(context: container.viewContext)
        self.recordStore = TrackerRecordStore(persistentContainer: container)
        self.trackerStore = TrackerStore(context: container.viewContext)
        
        self.trackerStore.delegate = self
        self.categoryStore.delegate = self
        
        // Загружаем категории и трекеры
        self.categories = categoryStore.categories
        self.trackers = trackerStore.getTrackers()
        
        self.completedTrackers = recordStore.completedTrackers
    }
    
    // MARK: - Business Logic
    func ensureDefaultCategory() {
        if !categories.contains(where: { $0.title == defaultCategoryTitle }) {
            let defaultCategory = TrackerCategory(id: UUID(), title: defaultCategoryTitle, trackers: [])
            categoryStore.add(defaultCategory)
            categories = categoryStore.categories
            onCategoriesUpdated?()
        }
    }
    
    func addTrackerToDefaultCategory(_ tracker: Tracker) {
        categoryStore.addTracker(tracker, to: defaultCategoryTitle)
        trackerStore.add(tracker)
        
        self.trackers = trackerStore.getTrackers()
        self.completedTrackers = recordStore.completedTrackers
        
        onCategoriesUpdated?()
        onTrackersUpdated?()
        updateCurrentDateForNewTracker(tracker)
    }
    
    private func updateCurrentDateForNewTracker(_ tracker: Tracker) {
        guard !tracker.schedule.isEmpty else { return }
        
        let todayWeekday = Calendar.current.component(.weekday, from: Date())
        let weekdaysMap: [Int: WeekDay] = [
            1: .sunday, 2: .monday, 3: .tuesday, 4: .wednesday,
            5: .thursday, 6: .friday, 7: .saturday
        ]
        
        let sortedDays = tracker.schedule.sorted { $0.rawValue < $1.rawValue }
        
        for offset in 0..<7 {
            let nextDayIndex = (todayWeekday + offset - 1) % 7 + 1
            if let day = weekdaysMap[nextDayIndex], sortedDays.contains(day),
               let nextDate = Calendar.current.date(byAdding: .day, value: offset, to: Date()) {
                currentDate = nextDate
                onDateChanged?(nextDate)
                break
            }
        }
    }
    
    func markTrackerAsCompleted(_ tracker: Tracker, on date: Date) {
        if let trackerCoreData = recordStore.fetchTracker(by: tracker.id) {
            recordStore.addRecord(for: trackerCoreData, date: date)
            trackers = trackerStore.getTrackers()
            completedTrackers = recordStore.completedTrackers
            onTrackersUpdated?()
        }
    }
    
    func unmarkTrackerAsCompleted(_ tracker: Tracker, on date: Date) {
        if let trackerCoreData = recordStore.fetchTracker(by: tracker.id) {
            recordStore.removeRecord(for: trackerCoreData, date: date)
            trackers = trackerStore.getTrackers()
            completedTrackers = recordStore.completedTrackers
            onTrackersUpdated?()
        }
    }
    
    func isTrackerCompleted(_ tracker: Tracker, on date: Date) -> Bool {
        guard let trackerCoreData = recordStore.fetchTracker(by: tracker.id) else {
            return false
        }
        return recordStore.isCompleted(for: trackerCoreData, date: date)
    }
}

// MARK: - Delegates
extension TrackersViewModel: TrackerStoreDelegate {
    func didUpdateTrackers(_ trackers: [Tracker]) {
        self.trackers = trackers
        onTrackersUpdated?()
    }
}

extension TrackersViewModel: TrackerCategoryStoreDelegate {
    func didUpdateCategories() {
        self.categories = categoryStore.categories
        onCategoriesUpdated?()
    }
}
