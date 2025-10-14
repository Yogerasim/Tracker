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
    // Словарь для запоминания исходной категории трекера
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
    func ensureDefaultCategory() {
        if !categories.contains(where: { $0.title == defaultCategoryTitle }) {
            let defaultCategory = TrackerCategory(id: UUID(), title: defaultCategoryTitle, trackers: [])
            categoryStore.add(defaultCategory)
            categories = categoryStore.categories
            onCategoriesUpdated?()
        }
    }
    
    func addTrackerToDefaultCategory(_ tracker: Tracker) {
        // Проверяем, что категория "Мои трекеры" существует
        ensureDefaultCategory()
        
        // Добавляем трекер только через trackerStore
        trackerStore.add(tracker)
        
        // Привязываем к категории через moveTracker
        categoryStore.moveTracker(tracker, to: defaultCategoryTitle)
        
        // Обновляем данные и уведомляем UI
        reloadTrackers()
        
    }
    
    func markTrackerAsCompleted(_ tracker: Tracker, on date: Date) {
        guard let trackerCoreData = recordStore.fetchTracker(by: tracker.id) else { return }
        recordStore.addRecord(for: trackerCoreData, date: date)
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
            let text = searchText.lowercased()

            filteredTrackers = trackers.filter { tracker in
                let matchesSearch = text.isEmpty || tracker.name.lowercased().contains(text)

                // Фильтруем по дате только если включен фильтр
                let matchesDate: Bool
                if isDateFilterEnabled {
                    let selectedDay = WeekDay.from(date: currentDate)
                    matchesDate = tracker.schedule.contains(selectedDay)
                } else {
                    matchesDate = true
                }

                return matchesSearch && matchesDate
            }

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
            let weekdayInt = Calendar.current.component(.weekday, from: currentDate)
            if let today = WeekDay(rawValue: weekdayInt) {
                filteredTrackers = trackers.filter { $0.schedule.contains(today) }
            } else {
                filteredTrackers = []
            }
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
        print("🟢 Edit tracker tapped: \(tracker.name)")
        onEditTracker?(tracker)
    }
    
    func deleteTracker(_ tracker: Tracker) {
        print("🔴 Request delete tracker: \(tracker.name)")
        trackerStore.delete(tracker)
        
        // Перезагружаем из store, чтобы state был консистентным
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
