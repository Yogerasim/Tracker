import Foundation
import CoreData

final class TrackersViewModel {
    
    // MARK: - Stores
    private let categoryStore: TrackerCategoryStore
    private let recordStore: TrackerRecordStore
    let trackerStore: TrackerStore
    
    
    // MARK: - Constants
    let pinnedCategoryTitle = NSLocalizedString("trackers.pinned_category", comment: "Закрепленные")
    private let defaultCategoryTitle = NSLocalizedString("trackers.default_category", comment: "Мои трекеры")
    
    // MARK: - State
    @Published private(set) var trackers: [Tracker] = []
    @Published private(set) var categories: [TrackerCategory] = []
    @Published var completedTrackers: [TrackerRecord] = []
    @Published var currentDate: Date = Date()
    @Published private(set) var filteredTrackers: [Tracker] = []
    @Published var searchText: String = "" {
        didSet { filterTrackers() }
    }
    private var originalCategoryMap: [UUID: String] = [:]
    
    // MARK: - Callbacks
    var onTrackersUpdated: (() -> Void)?
    var onCategoriesUpdated: (() -> Void)?
    var onDateChanged: ((Date) -> Void)?
    var nonEmptyCategories: [TrackerCategory] {
        return categories.filter { !$0.trackers.isEmpty }
    }
    var onEditTracker: ((Tracker) -> Void)?
    var selectedFilterIndex: Int = 0 {
        didSet {
            applyFilter()
        }
    }
    var isDateFilterEnabled: Bool = false
    
    // MARK: - Init
    init(container: NSPersistentContainer = CoreDataStack.shared.persistentContainer) {
        self.categoryStore = TrackerCategoryStore(context: container.viewContext)
        self.recordStore = TrackerRecordStore(persistentContainer: container)
        self.trackerStore = TrackerStore(context: container.viewContext)
        
        self.trackerStore.delegate = self
        self.categoryStore.delegate = self
        
        loadData()
    }
    
    private func loadData() {
        self.trackers = trackerStore.getTrackers()
        self.categories = categoryStore.categories
        self.completedTrackers = recordStore.completedTrackers
        self.filteredTrackers = self.trackers
    }
    
    // MARK: - Business Logic
    
    func addTrackerToDefaultCategory(_ tracker: Tracker) {
        // Проверяем, существует ли категория "Мои трекеры"
        if let _ = categories.first(where: { $0.title == defaultCategoryTitle }) {
            // Добавляем трекер только если категория есть
            trackerStore.add(tracker)
            categoryStore.moveTracker(tracker, to: defaultCategoryTitle)
        } else {
            // Если категории нет — просто добавляем трекер в базу без категории
            trackerStore.add(tracker)
        }
        
        reloadTrackers()
    }
    
    func markTrackerAsCompleted(_ tracker: Tracker, on date: Date) {
        guard let trackerCoreData = recordStore.fetchTracker(by: tracker.id) else { return }
        recordStore.addRecord(for: trackerCoreData, date: date)
        reloadTrackers()
    }
    
    func unmarkTrackerAsCompleted(_ tracker: Tracker, on date: Date) {
            guard let trackerCoreData = recordStore.fetchTracker(by: tracker.id) else { return }
            recordStore.removeRecord(for: trackerCoreData, date: date)
            reloadTrackers()
        }
    
    func isTrackerCompleted(_ tracker: Tracker, on date: Date) -> Bool {
        guard let trackerCoreData = recordStore.fetchTracker(by: tracker.id) else { return false }
        return recordStore.isCompleted(for: trackerCoreData, date: date)
    }
    
    // MARK: - Фильтрация
    func filterByDate() {
        isDateFilterEnabled = true
        filterTrackers()
        onDateChanged?(currentDate)
    }
    
    private func filterTrackers() {
        print("\n🧩 [filterTrackers] — started")
        print("🔸 isDateFilterEnabled = \(isDateFilterEnabled)")
        print("🔸 currentDate = \(currentDate.formatted(date: .abbreviated, time: .omitted))")
        print("🔸 searchText = '\(searchText)' (lowercased: '\(searchText.lowercased())')")
        print("🔸 total trackers before filter: \(trackers.count)")

        let text = searchText.lowercased()
        
        filteredTrackers = trackers.filter { tracker in
            let matchesSearch = text.isEmpty || tracker.name.lowercased().contains(text)
            
            let matchesDate: Bool
            if isDateFilterEnabled {
                matchesDate = tracker.schedule.contains(currentDate.weekDay)
            } else {
                matchesDate = true
            }
            
            // Подробный лог для каждого трекера
            print("  • Checking tracker: '\(tracker.name)'")
            print("    - schedule: \(tracker.schedule)")
            print("    - matchesSearch: \(matchesSearch)")
            print("    - matchesDate: \(matchesDate)")
            print("    - result: \(matchesSearch && matchesDate)")
            
            return matchesSearch && matchesDate
        }

        print("✅ Filter result — filteredTrackers.count = \(filteredTrackers.count)")
        print("✅ Filtered trackers: \(filteredTrackers.map { $0.name })\n")
        
        onTrackersUpdated?()
    }
    
    private func reloadTrackers() {
        self.trackers = trackerStore.getTrackers()
        self.completedTrackers = recordStore.completedTrackers
        filterTrackers()
        
        NotificationCenter.default.post(name: .trackerRecordsDidChange, object: nil)
    }
    
    private func applyFilter() {
        switch selectedFilterIndex {
        case 0:
            filteredTrackers = trackers // Все трекеры
        case 1:
            // Трекеры на сегодня
            let today = currentDate.weekDay
            filteredTrackers = trackers.filter { $0.schedule.contains(today) }
        case 2:
            // Завершенные
            filteredTrackers = trackers.filter { isTrackerCompleted($0, on: currentDate) }
        case 3:
            // Не завершенные
            filteredTrackers = trackers.filter { !isTrackerCompleted($0, on: currentDate) }
        default:
            filteredTrackers = trackers
        }
        
        onTrackersUpdated?()
    }
}

// MARK: - Pin / Unpin
extension TrackersViewModel {
    
    func pinTracker(_ tracker: Tracker) {
        var pinnedCategory = categories.first(where: { $0.title == pinnedCategoryTitle })
        if pinnedCategory == nil {
            pinnedCategory = TrackerCategory(id: UUID(), title: pinnedCategoryTitle, trackers: [])
            categoryStore.add(pinnedCategory!)
            categories.insert(pinnedCategory!, at: 0)
            onCategoriesUpdated?()
        }
        
        originalCategoryMap[tracker.id] = tracker.trackerCategory?.title ?? defaultCategoryTitle
        
        categoryStore.moveTracker(tracker, to: pinnedCategoryTitle)
        
        reloadTrackers()
        onTrackersUpdated?()
    }
    
    func unpinTracker(_ tracker: Tracker) {
        guard let originalTitle = originalCategoryMap[tracker.id] else { return }
        
        categoryStore.moveTracker(tracker, to: originalTitle)
        originalCategoryMap.removeValue(forKey: tracker.id)
        
        reloadTrackers()
        onTrackersUpdated?()
    }
    
    
    
    private func createCategoryIfMissing(title: String) -> TrackerCategory {
        let category = TrackerCategory(id: UUID(), title: title, trackers: [])
        categories.append(category)
        categoryStore.add(category)
        onCategoriesUpdated?()
        return category
    }
}

// MARK: - Edit / Delete
extension TrackersViewModel {
    
    func editTracker(_ tracker: Tracker) {
        print("🟢 Edit tracker tapped: \(tracker.name)")
        onEditTracker?(tracker)
    }
    
    func deleteTracker(_ tracker: Tracker) {
        print("🔴 Request delete tracker: \(tracker.name)")
        trackerStore.delete(tracker)
        
        reloadTrackers()
        onTrackersUpdated?()
        print("✅ Deleted tracker: \(tracker.name). trackers.count = \(trackers.count)")
        
        NotificationCenter.default.post(name: .trackersDidChange, object: nil)
    }
}

// MARK: - Delegates
extension TrackersViewModel: TrackerStoreDelegate {
    func didUpdateTrackers(_ trackers: [Tracker]) {
        self.trackers = trackers
        filterTrackers()
        onTrackersUpdated?()
    }
}

extension TrackersViewModel: TrackerCategoryStoreDelegate {
    func didUpdateCategories() {
        self.categories = categoryStore.categories
        onCategoriesUpdated?()
    }
}
extension Date {
    var weekDay: WeekDay {
        WeekDay.from(date: self)
    }
}
