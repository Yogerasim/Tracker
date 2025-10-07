import Foundation
import CoreData

final class TrackersViewModel {
    
    // MARK: - Stores
    private let categoryStore: TrackerCategoryStore
    private let recordStore: TrackerRecordStore
    let trackerStore: TrackerStore
    
    // MARK: - Constants
    let pinnedCategoryTitle = "Закрепленные"
    private let defaultCategoryTitle = "Мои трекеры"
    
    // MARK: - State
    @Published private(set) var trackers: [Tracker] = []
    @Published private(set) var categories: [TrackerCategory] = []
    @Published var completedTrackers: [TrackerRecord] = []
    @Published var currentDate: Date = Date()
    @Published private(set) var filteredTrackers: [Tracker] = []
    @Published var searchText: String = "" {
        didSet { filterTrackers() }
    }
    
    // Словарь для запоминания исходной категории трекера
    private var originalCategoryMap: [UUID: String] = [:]
    
    // MARK: - Callbacks
    var onTrackersUpdated: (() -> Void)?
    var onCategoriesUpdated: (() -> Void)?
    var onDateChanged: ((Date) -> Void)?
    var nonEmptyCategories: [TrackerCategory] {
        return categories.filter { !$0.trackers.isEmpty }
    }
    
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
    
    private func filterTrackers() {
        let text = searchText.lowercased()
        filteredTrackers = text.isEmpty ? trackers : trackers.filter { $0.name.lowercased().contains(text) }
        onTrackersUpdated?()
    }
    
    private func reloadTrackers() {
        self.trackers = trackerStore.getTrackers()
        self.completedTrackers = recordStore.completedTrackers
        filterTrackers()
    }
    
    
    
}

// MARK: - Pin / Unpin
extension TrackersViewModel {
    
    func pinTracker(_ tracker: Tracker) {
        // Находим или создаём категорию "Закрепленные"
        var pinnedCategory = categories.first(where: { $0.title == pinnedCategoryTitle })
        if pinnedCategory == nil {
            pinnedCategory = TrackerCategory(id: UUID(), title: pinnedCategoryTitle, trackers: [])
            categoryStore.add(pinnedCategory!)
            categories.insert(pinnedCategory!, at: 0)
            onCategoriesUpdated?()
        }
        
        // Сохраняем исходную категорию
        originalCategoryMap[tracker.id] = tracker.trackerCategory?.title ?? defaultCategoryTitle
        
        // Удаляем из текущей категории и добавляем в "Закрепленные"
        categoryStore.moveTracker(tracker, to: pinnedCategoryTitle)
        
        reloadTrackers()
        onTrackersUpdated?()
    }
    
    func unpinTracker(_ tracker: Tracker) {
        guard let originalTitle = originalCategoryMap[tracker.id] else { return }
        
        // Перемещаем обратно в исходную категорию
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
        print("Edit tracker: \(tracker.name)")
    }
    
    func deleteTracker(_ tracker: Tracker) {
        trackerStore.delete(tracker)
        
        
        trackers.removeAll { $0.id == tracker.id }
        filteredTrackers.removeAll { $0.id == tracker.id }
        completedTrackers.removeAll { $0.trackerId == tracker.id }
        
        onTrackersUpdated?()
        print("Deleted tracker: \(tracker.name)")
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
