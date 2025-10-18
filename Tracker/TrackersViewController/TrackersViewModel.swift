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
    private var updateWorkItem: DispatchWorkItem?
    
    // MARK: - Callbacks
    var onTrackersUpdated: (() -> Void)?
    var onCategoriesUpdated: (() -> Void)?
    var onDateChanged: ((Date) -> Void)?
    var onEditTracker: ((Tracker) -> Void)?
    
    var nonEmptyCategories: [TrackerCategory] {
        categories.filter { !$0.trackers.isEmpty }
    }
    
    var selectedFilterIndex: Int = 0 {
        didSet { applyFilter() }
    }
    
    var isDateFilterEnabled: Bool = false
    
    // MARK: - Init
    init(container: NSPersistentContainer = CoreDataStack.shared.persistentContainer) {
        self.categoryStore = TrackerCategoryStore(context: container.viewContext)
        self.recordStore = TrackerRecordStore(persistentContainer: container)
        self.trackerStore = TrackerStore(context: container.viewContext)
        
        self.trackerStore.delegate = self
        self.categoryStore.delegate = self
        self.recordStore.delegate = self
        
        loadData()
    }
    
    private func loadData() {
        trackers = trackerStore.getTrackers()
        categories = categoryStore.categories
        completedTrackers = recordStore.completedTrackers
        filteredTrackers = trackers
    }
    
    // MARK: - Business Logic
    
    func addTrackerToDefaultCategory(_ tracker: Tracker) {
        if let _ = categories.first(where: { $0.title == defaultCategoryTitle }) {
            trackerStore.add(tracker)
            categoryStore.moveTracker(tracker, to: defaultCategoryTitle)
        } else {
            trackerStore.add(tracker)
        }
        reloadTrackers()
    }
    
    func markTrackerAsCompleted(_ tracker: Tracker, on date: Date, completion: (() -> Void)? = nil) {
        print("🟢 [VM] markTrackerAsCompleted — \(tracker.name) on \(date.formatted())")
        guard let trackerCoreData = recordStore.fetchTracker(by: tracker.id) else {
            print("⚠️ [VM] fetchTracker FAILED for id \(tracker.id)")
            return
        }
        
        recordStore.addRecord(for: trackerCoreData, date: date)
        DispatchQueue.main.async {
            self.reloadTrackers()
            completion?() // ✅ вызов опционального completion
        }
    }

    func unmarkTrackerAsCompleted(_ tracker: Tracker, on date: Date, completion: (() -> Void)? = nil) {
        print("🔴 [VM] unmarkTrackerAsCompleted — \(tracker.name) on \(date.formatted())")
        guard let trackerCoreData = recordStore.fetchTracker(by: tracker.id) else {
            print("⚠️ [VM] fetchTracker FAILED for id \(tracker.id)")
            return
        }
        
        recordStore.removeRecord(for: trackerCoreData, date: date)
        DispatchQueue.main.async {
            self.reloadTrackers()
            completion?() // ✅ вызов опционального completion
        }
    }
    func isTrackerCompleted(_ tracker: Tracker, on date: Date) -> Bool {
        let result: Bool
        if let trackerCoreData = recordStore.fetchTracker(by: tracker.id) {
            result = recordStore.isCompleted(for: trackerCoreData, date: date)
        } else {
            result = false
        }
        print("📘 [VM] isTrackerCompleted(\(tracker.name)) = \(result)")
        return result
    }
    
    // MARK: - Filtering
    
    func filterByDate() {
        isDateFilterEnabled = true
        filterTrackers()
        onDateChanged?(currentDate)
    }
    
    func reloadWithDebounce() {
        updateWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.filterTrackers()
        }
        updateWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }
    
    private func filterTrackers() {
        print("\n🧩 [filterTrackers] — started")
        print("🔸 isDateFilterEnabled = \(isDateFilterEnabled)")
        print("🔸 currentDate = \(currentDate.formatted(date: .abbreviated, time: .omitted))")
        print("🔸 searchText = '\(searchText)'")
        print("🔸 total trackers before filter: \(trackers.count)")

        let text = searchText.lowercased()
        
        filteredTrackers = trackers.filter { tracker in
            let matchesSearch = text.isEmpty || tracker.name.lowercased().contains(text)
            let matchesDate = !isDateFilterEnabled || tracker.schedule.contains(currentDate.weekDay)
            
            print("  • \(tracker.name): search=\(matchesSearch), date=\(matchesDate)")
            return matchesSearch && matchesDate
        }

        print("✅ Filter result — \(filteredTrackers.count) trackers")
        print("✅ Filtered names: \(filteredTrackers.map { $0.name })\n")
        
        onTrackersUpdated?()
    }
    
    private func reloadTrackers() {
        trackers = trackerStore.getTrackers()
        completedTrackers = recordStore.completedTrackers
        filterTrackers()
        NotificationCenter.default.post(name: .trackerRecordsDidChange, object: nil)
    }
    
    private func applyFilter() {
        switch selectedFilterIndex {
        case 0:
            filteredTrackers = trackers
        case 1:
            filteredTrackers = trackers.filter { $0.schedule.contains(currentDate.weekDay) }
        case 2:
            filteredTrackers = trackers.filter { isTrackerCompleted($0, on: currentDate) }
        case 3:
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
        reloadWithDebounce()
        onTrackersUpdated?()
    }
}

extension TrackersViewModel: TrackerCategoryStoreDelegate {
    func didUpdateCategories() {
        self.categories = categoryStore.categories
        onCategoriesUpdated?()
    }
}

extension TrackersViewModel: TrackerRecordStoreDelegate {
    func didUpdateRecords() {
        print("📡 [TrackersViewModel] didUpdateRecords() — refreshing completedTrackers")
        completedTrackers = recordStore.completedTrackers
        reloadWithDebounce()
    }
}

extension Date {
    var weekDay: WeekDay {
        WeekDay.from(date: self)
    }
}
