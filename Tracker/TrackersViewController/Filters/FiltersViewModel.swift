import Foundation
import Combine

final class FiltersViewModel {
    
    // MARK: - Published properties
    @Published private(set) var filteredTrackers: [Tracker] = []
    @Published var selectedFilterIndex: Int = 0 { didSet { applyAllFilters(for: selectedDate) } }
    @Published var selectedDate: Date = Date() { didSet { applyAllFilters(for: selectedDate) } }
    
    // MARK: - Other properties
    var searchText: String = "" { didSet { applyAllFilters(for: selectedDate) } }
    var selectedCategory: TrackerCategory?
    var onFilteredTrackersUpdated: (() -> Void)?
    
    private let trackersProvider: () -> [Tracker]
    private let isCompletedProvider: (Tracker, Date) -> Bool
    private let dateFilter: TrackersDateFilter
    private let calendar = Calendar.current
    
    // MARK: - Init
    init(
        trackersProvider: @escaping () -> [Tracker],
        isCompletedProvider: @escaping (Tracker, Date) -> Bool,
        dateFilter: TrackersDateFilter
    ) {
        self.trackersProvider = trackersProvider
        self.isCompletedProvider = isCompletedProvider
        self.dateFilter = dateFilter
    }
    
    // MARK: - Unified filtering
    private var hasInitialDataLoaded = false
    
    func setInitialDataLoaded() {
        hasInitialDataLoaded = true
        AppLogger.trackers.info("[Filter] ⚙️ Initial data loaded, filters can now apply")
        applyAllFilters(for: selectedDate)
    }
    
    func applyAllFilters(for date: Date) {
        guard hasInitialDataLoaded else {
            AppLogger.trackers.debug("[Filter] ⏳ Пропускаем фильтрацию — данные ещё не загружены")
            return
        }

        var trackers = trackersProvider()
        AppLogger.trackers.info("[Filter] 🔄 Начинаем фильтрацию для даты \(date.startOfDayUTC().formatted()) — всего \(trackers.count) трекеров")

        // 🧩 Новый лог
        for t in trackers {
            AppLogger.trackers.debug("[Filter] ⚙️ \(t.name) schedule: \(t.schedule.map { $0.rawValue })")
        }

        trackers = dateFilter.filterTrackersByDay(trackers, date: date)
        trackers = dateFilter.filterTrackersByIndex(
            trackers,
            selectedFilterIndex: selectedFilterIndex,
            currentDate: date,
            searchText: searchText,
            completionChecker: isCompletedProvider
        )
        AppLogger.trackers.info("[Filter] ✅ Финальное количество после всех фильтров: \(trackers.count)")
        filteredTrackers = trackers
        onFilteredTrackersUpdated?()
    }
    
    // MARK: - Helpers
    func selectFilter(index: Int) {
        selectedFilterIndex = index
    }
}
