import Combine
import Foundation

final class FiltersViewModel {
    @Published private(set) var filteredTrackers: [Tracker] = []
    @Published var selectedFilterIndex: Int = 0 {
        didSet {
            AppLogger.trackers.info("[FiltersVM] selectedFilterIndex changed → \(selectedFilterIndex)",
                                    metadata: ["source": "\(Thread.callStackSymbols.prefix(8))"])
        }
    }
    @Published var selectedDate: Date = .init()
    @Published var searchText: String = ""

    var selectedCategory: TrackerCategory?
    var onFilteredTrackersUpdated: (() -> Void)?
    var onSingleTrackerUpdated: ((Tracker, Bool) -> Void)?

    private let trackersProvider: () -> [Tracker]
    private let isCompletedProvider: (Tracker, Date) -> Bool
    private let dateFilter: TrackersDateFilter
    private var cancellables = Set<AnyCancellable>()
    private var hasInitialDataLoaded = false
  

    // 🔹 Защита от дублирующихся вызовов
    private var isApplyingFilters = false
    private var lastAppliedDate: Date?
    private var lastAppliedFilterIndex: Int?
    private var applyFiltersWorkItem: DispatchWorkItem?

    init(
        trackersProvider: @escaping () -> [Tracker],
        isCompletedProvider: @escaping (Tracker, Date) -> Bool,
        dateFilter: TrackersDateFilter
    ) {
        self.trackersProvider = trackersProvider
        self.isCompletedProvider = isCompletedProvider
        self.dateFilter = dateFilter
        setupFilteringPipeline()
    }

    private func setupFilteringPipeline() {
        Publishers.CombineLatest3($selectedDate, $selectedFilterIndex, $searchText)
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] date, _, _ in
                guard let self else { return }
                guard self.hasInitialDataLoaded else { return }
                self.applyAllFiltersDebounced(for: date)
            }
            .store(in: &cancellables)
    }

    func setInitialDataLoaded() {
        hasInitialDataLoaded = true
        applyAllFiltersDebounced(for: selectedDate)
    }

    // 🔹 Debounce + защита от дублирующихся applyAllFilters
    func applyAllFiltersDebounced(for date: Date) {
        applyFiltersWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.applyAllFiltersOnce(for: date)
        }
        applyFiltersWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: workItem)
    }

    private func applyAllFiltersOnce(for date: Date) {
        // Если дата и индекс фильтра не изменились — пропускаем
        if lastAppliedDate == date && lastAppliedFilterIndex == selectedFilterIndex {
            AppLogger.trackers.debug("[FiltersVM] Skipping applyAllFilters: no changes (date/filterIndex same)")
            return
        }
        lastAppliedDate = date
        lastAppliedFilterIndex = selectedFilterIndex

        applyAllFilters(for: date)
    }
    

    // 🔹 Собственно, фильтрация и обновление UI
    func applyAllFilters(for date: Date) {
        AppLogger.trackers.info("[FiltersVM] applyAllFilters(for: \(date.short)) start")
        guard !isApplyingFilters else {
            AppLogger.trackers.debug("[FiltersVM] applyAllFilters skipped: already running")
            return
        }
        isApplyingFilters = true
        defer { isApplyingFilters = false }

        var trackers = trackersProvider()
        AppLogger.trackers.info("[FiltersVM] Got \(trackers.count) trackers from provider")

        // 1. Фильтрация по дню недели
        trackers = dateFilter.filterTrackersByDay(trackers, date: date)
        AppLogger.trackers.info("[FiltersVM] After filterByDay: \(trackers.count)")

        // 2. Применяем фильтр по индексу (Completed / NotCompleted)
        if selectedFilterIndex != 0 {
            trackers = dateFilter.filterTrackersByIndex(
                trackers,
                selectedFilterIndex: selectedFilterIndex,
                currentDate: date,
                searchText: searchText,
                completionChecker: isCompletedProvider
            )
            AppLogger.trackers.info("[FiltersVM] After filterByIndex(\(selectedFilterIndex)): \(trackers.count)")
        } else {
            AppLogger.trackers.info("[FiltersVM] Skipping completed/notCompleted filter (index = 0)")
        }

        // 3. Обновляем UI только если список изменился
        if trackers.map({ $0.id }) != filteredTrackers.map({ $0.id }) {
            AppLogger.trackers.info("[FiltersVM] Filtered trackers changed, updating list and UI")
            filteredTrackers = trackers
            onFilteredTrackersUpdated?()
        } else {
            AppLogger.trackers.debug("[FiltersVM] No change in filtered trackers list")
        }
        
    }

    func selectFilter(index: Int) {
        selectedFilterIndex = index
    }

    /// 🔄 Обновление одного трекера при смене галочки
    func updateTracker(_ tracker: Tracker) {
        AppLogger.trackers.info("[FiltersVM] updateTracker called for tracker: \(tracker.name) (\(tracker.id))")
        
        if let index = filteredTrackers.firstIndex(where: { $0.id == tracker.id }) {
            filteredTrackers[index] = tracker
            AppLogger.trackers.info("[FiltersVM] Tracker \(tracker.name) updated locally")
            onFilteredTrackersUpdated?()
        } else {
            AppLogger.trackers.warning("[FiltersVM] Tracker \(tracker.name) not found in filtered list")
        }
    }
    func updateSingleTracker(_ tracker: Tracker, completed: Bool) {
        onSingleTrackerUpdated?(tracker, completed)
    }
}
