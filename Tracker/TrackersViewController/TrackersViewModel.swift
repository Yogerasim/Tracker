import Combine
import CoreData
import Logging

final class TrackersViewModel {
    private let categoryStore: TrackerCategoryStore
    var recordStore: TrackerRecordStore
    let trackerStore: TrackerStore
    var cellViewModels: [UUID: TrackerCellViewModel] = [:]
    let pinnedCategoryTitle = NSLocalizedString("trackers.pinned_category", comment: "Закрепленные")
    @Published private(set) var trackers: [Tracker] = []
    @Published private(set) var categories: [TrackerCategory] = []
    @Published var completedTrackers: [TrackerRecord] = []
    @Published var currentDate: Date = .init() {
        didSet { onDateChanged?(currentDate) }
    }

    private var originalCategoryMap: [UUID: String] = [:]
    private var reloadWorkItem: DispatchWorkItem?
    var onTrackersUpdated: (() -> Void)?
    var onCategoriesUpdated: (() -> Void)?
    var onDateChanged: ((Date) -> Void)?
    var onEditTracker: ((Tracker) -> Void)?
    var onSingleTrackerUpdated: ((Tracker, Bool) -> Void)?
    var lastUpdatedTrackerID: UUID?
    convenience init(container: NSPersistentContainer = CoreDataStack.shared.persistentContainer) {
        let categoryStore = TrackerCategoryStore(context: container.viewContext)
        let trackerStore = TrackerStore(context: container.viewContext)
        let recordStore = TrackerRecordStore(persistentContainer: container)
        self.init(categoryStore: categoryStore, trackerStore: trackerStore, recordStore: recordStore)
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
        scheduleTrackersUpdate()
    }

    func reloadTrackers() {
        trackers = trackerStore.getTrackers()
        completedTrackers = recordStore.completedTrackers
        trackers.forEach { _ = makeCellViewModel(for: $0) }
        scheduleTrackersUpdate()
    }

    private func scheduleTrackersUpdate() {
        reloadWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.onTrackersUpdated?()
        }
        reloadWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: workItem)
    }

    func addTracker(_ tracker: Tracker, to categoryTitle: String) {
        guard !trackers.contains(where: { $0.id == tracker.id }) else { return }
        categoryStore.addTracker(tracker, to: categoryTitle)
        trackers = trackerStore.getTrackers()
        trackers.forEach { _ = makeCellViewModel(for: $0) }
        scheduleTrackersUpdate()
    }
    func refreshViewModel(for tracker: Tracker) {
        let newVM = TrackerCellViewModel(tracker: tracker,
                                         recordStore: recordStore,
                                         currentDate: currentDate)
        cellViewModels[tracker.id] = newVM
    }

    // MARK: - TrackersViewModel
    func markTrackerAsCompleted(_ tracker: Tracker, on date: Date, completion: (() -> Void)? = nil) {
        AppLogger.trackers.info("[VM] markTrackerAsCompleted called for tracker: \(tracker.name) (\(tracker.id)) on \(date.short)")

        guard let trackerCoreData = recordStore.fetchTrackerInViewContext(by: tracker.id) else {
            AppLogger.trackers.warning("[VM] Tracker not found in CoreData for id \(tracker.id)")
            return
        }

        recordStore.addRecord(for: trackerCoreData, date: date)
        lastUpdatedTrackerID = tracker.id
        AppLogger.trackers.info("[VM] Record added, lastUpdatedTrackerID = \(self.lastUpdatedTrackerID?.uuidString ?? "nil")")

        if let updated = trackerStore.getTrackers().first(where: { $0.id == tracker.id }) {
            AppLogger.trackers.info("[VM] Notifying FiltersVM about updated tracker: \(updated.name)")
            onSingleTrackerUpdated?(updated, true)  // FiltersVM получит свежий трекер
        }

        scheduleTrackersUpdate()
        completion?()
    }

    func unmarkTrackerAsCompleted(_ tracker: Tracker, on date: Date, completion: (() -> Void)? = nil) {
        AppLogger.trackers.info("[VM] unmarkTrackerAsCompleted called for tracker: \(tracker.name) (\(tracker.id)) on \(date.short)")

        guard let trackerCoreData = recordStore.fetchTrackerInViewContext(by: tracker.id) else {
            AppLogger.trackers.warning("[VM] Tracker not found in CoreData for id \(tracker.id)")
            return
        }

        recordStore.removeRecord(for: trackerCoreData, date: date)
        lastUpdatedTrackerID = tracker.id
        AppLogger.trackers.info("[VM] Record removed, lastUpdatedTrackerID = \(self.lastUpdatedTrackerID?.uuidString ?? "nil")")

        if let updated = trackerStore.getTrackers().first(where: { $0.id == tracker.id }) {
            AppLogger.trackers.info("[VM] Notifying FiltersVM about updated tracker: \(updated.name)")
            onSingleTrackerUpdated?(updated, false)
        }

        scheduleTrackersUpdate()
        completion?()
    }
    
    func isTrackerCompleted(_ tracker: Tracker, on date: Date) -> Bool {
        let normalized = normalizedDate(date)
        guard let trackerCoreData = recordStore.fetchTrackerInViewContext(by: tracker.id) else { return false }
        return recordStore.isCompleted(for: trackerCoreData, date: normalized)
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
        originalCategoryMap[tracker.id] = tracker.trackerCategory?.title ?? ""
        categoryStore.moveTracker(tracker, to: pinnedCategoryTitle)
        reloadTrackers()
    }

    func unpinTracker(_ tracker: Tracker) {
        guard let originalTitle = originalCategoryMap[tracker.id] else { return }
        categoryStore.moveTracker(tracker, to: originalTitle)
        originalCategoryMap.removeValue(forKey: tracker.id)
        reloadTrackers()
    }
}

extension TrackersViewModel {
    func editTracker(_ tracker: Tracker) {
        if let vm = cellViewModels[tracker.id] {
            vm.tracker = tracker
            vm.refreshState()
        }
        lastUpdatedTrackerID = tracker.id
        onEditTracker?(tracker)
        scheduleTrackersUpdate()
    }

    func deleteTracker(_ tracker: Tracker) {
        trackerStore.delete(tracker)
        reloadTrackers()
        NotificationCenter.default.post(name: .trackersDidChange, object: nil)
    }
}

extension TrackersViewModel: TrackerStoreDelegate {
    func didUpdateTrackers(_ trackers: [Tracker]) {
        self.trackers = trackers
        scheduleTrackersUpdate()
    }
}

extension TrackersViewModel: TrackerCategoryStoreDelegate {
    func didUpdateCategories() {
        categories = categoryStore.categories
        onCategoriesUpdated?()
    }
}

extension TrackersViewModel: TrackerRecordStoreDelegate {
    func didUpdateRecords() {
        completedTrackers = recordStore.completedTrackers
        scheduleTrackersUpdate()
    }
}

extension Date {
    var weekDay: WeekDay {
        WeekDay.from(date: self)
    }
}

extension TrackersViewModel {
    func searchTrackers(by text: String) -> [Tracker] {
        guard !text.isEmpty else { return trackers }
        let lowercased = text.lowercased()
        return trackers.filter { $0.name.lowercased().contains(lowercased) }
    }
}
