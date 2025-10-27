import CoreData
import Logging

final class TrackersViewModel {
    
    
    private let categoryStore: TrackerCategoryStore
    let recordStore: TrackerRecordStore
    let trackerStore: TrackerStore
    var cellViewModels: [UUID: TrackerCellViewModel] = [:]
    
    
    let pinnedCategoryTitle = NSLocalizedString("trackers.pinned_category", comment: "Закрепленные")
    private let defaultCategoryTitle = NSLocalizedString("trackers.default_category", comment: "Мои трекеры")
    
    
    @Published private(set) var trackers: [Tracker] = []
    @Published private(set) var categories: [TrackerCategory] = []
    @Published var completedTrackers: [TrackerRecord] = []
    
    @Published var currentDate: Date = Date() {
        didSet { onDateChanged?(currentDate) }
    }
    
    private var originalCategoryMap: [UUID: String] = [:]
    private var updateWorkItem: DispatchWorkItem?
    private var reloadWorkItem: DispatchWorkItem?
    
    
    var onTrackersUpdated: (() -> Void)?
    var onCategoriesUpdated: (() -> Void)?
    var onDateChanged: ((Date) -> Void)?
    var onEditTracker: ((Tracker) -> Void)?
    
    
    init(container: NSPersistentContainer = CoreDataStack.shared.persistentContainer) {
        self.categoryStore = TrackerCategoryStore(context: container.viewContext)
        self.trackerStore = TrackerStore(context: container.viewContext)
        self.recordStore = TrackerRecordStore(persistentContainer: container)
        
        self.trackerStore.delegate = self
        self.categoryStore.delegate = self
        self.recordStore.delegate = self
        
        loadData()
    }
    
    
    init(
        categoryStore: TrackerCategoryStore,
        trackerStore: TrackerStore,
        recordStore: TrackerRecordStore
    ) {
        self.categoryStore = categoryStore
        self.trackerStore = trackerStore
        self.recordStore = recordStore
        
        self.trackerStore.delegate = self
        self.categoryStore.delegate = self
        self.recordStore.delegate = self
    }
    
    
    func loadData() {
        
        trackers = trackerStore.getTrackers()
        completedTrackers = recordStore.completedTrackers
        categories = categoryStore.categories
        
        onTrackersUpdated?()
    }
    
    func reloadTrackers() {
        trackers = trackerStore.getTrackers()
        completedTrackers = recordStore.completedTrackers
        
        onTrackersUpdated?()
    }
    
    
    
    func addTrackerToDefaultCategory(_ tracker: Tracker) {
        guard !trackers.contains(where: { $0.id == tracker.id }) else { return }
        trackerStore.add(tracker)
        
        if let _ = categories.first(where: { $0.title == defaultCategoryTitle }) {
            categoryStore.moveTracker(tracker, to: defaultCategoryTitle)
        }
        
        trackers.forEach { tracker in
            _ = makeCellViewModel(for: tracker)
        }
        reloadTrackers()
    }
    
    func markTrackerAsCompleted(_ tracker: Tracker, on date: Date, completion: (() -> Void)? = nil) {
        guard let trackerCoreData = recordStore.fetchTrackerInViewContext(by: tracker.id) else { return }
        recordStore.addRecord(for: trackerCoreData, date: date)
        completion?()
    }

    func unmarkTrackerAsCompleted(_ tracker: Tracker, on date: Date, completion: (() -> Void)? = nil) {
        guard let trackerCoreData = recordStore.fetchTrackerInViewContext(by: tracker.id) else { return }
        recordStore.removeRecord(for: trackerCoreData, date: date)
        completion?()
    }
    
    func isTrackerCompleted(_ tracker: Tracker, on date: Date) -> Bool {
        let normalized = normalizedDate(date)
        let result: Bool
        if let trackerCoreData = recordStore.fetchTrackerInViewContext(by: tracker.id) {
            result = recordStore.isCompleted(for: trackerCoreData, date: normalized)
        } else {
            result = false
        }
        
        return result
    }
    
    func makeCellViewModel(for tracker: Tracker) -> TrackerCellViewModel {
        if let existingVM = cellViewModels[tracker.id] {
            existingVM.updateCurrentDate(currentDate)
            return existingVM
        } else {
            let newVM = TrackerCellViewModel(tracker: tracker, recordStore: recordStore, currentDate: currentDate)
            cellViewModels[tracker.id] = newVM
            return newVM
        }
    }
    
    private func normalizedDate(_ date: Date) -> Date {
        date.startOfDayUTC()
    }
}


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


extension TrackersViewModel {
    func editTracker(_ tracker: Tracker) {
        
        if let vm = cellViewModels[tracker.id] {
            vm.tracker = tracker
            vm.refreshState()
        }
        onEditTracker?(tracker)
    }
    
    func deleteTracker(_ tracker: Tracker) {
        
        trackerStore.delete(tracker)
        reloadTrackers()
        onTrackersUpdated?()
        
        NotificationCenter.default.post(name: .trackersDidChange, object: nil)
    }
}


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

extension TrackersViewModel: TrackerRecordStoreDelegate {
    func didUpdateRecords() {
        reloadWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.completedTrackers = self.recordStore.completedTrackers
            self.onTrackersUpdated?()
        }
        reloadWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
    }
}

extension Date {
    var weekDay: WeekDay {
        WeekDay.from(date: self)
    }
}
