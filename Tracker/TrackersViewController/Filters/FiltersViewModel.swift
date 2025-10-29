import Foundation
import Combine

final class FiltersViewModel {
    
    @Published private(set) var filteredTrackers: [Tracker] = []
    @Published var selectedFilterIndex: Int = 0
    @Published var selectedDate: Date = Date()
    @Published var searchText: String = ""
    
    var selectedCategory: TrackerCategory?
    var onFilteredTrackersUpdated: (() -> Void)?
    
    private let trackersProvider: () -> [Tracker]
    private let isCompletedProvider: (Tracker, Date) -> Bool
    private let dateFilter: TrackersDateFilter
    private let calendar = Calendar.current
    private var cancellables = Set<AnyCancellable>()
    private var hasInitialDataLoaded = false
    
    // MARK: - Init
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
    
    // MARK: - Combine pipeline
    private func setupFilteringPipeline() {
        Publishers.CombineLatest3($selectedDate, $selectedFilterIndex, $searchText)
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] (date, filterIndex, text) in
                guard let self else { return }
                guard self.hasInitialDataLoaded else {
                    return
                }
                self.applyAllFilters(for: date)
            }
            .store(in: &cancellables)
    }
    
    func setInitialDataLoaded() {
        hasInitialDataLoaded = true
        applyAllFilters(for: selectedDate)
    }

    // MARK: - Filtering logic
    func applyAllFilters(for date: Date) {
        var trackers = trackersProvider()
        print("🔎 [FiltersViewModel] Исходные трекеры: \(trackers.map { $0.name })")

        // 1️⃣ Фильтр по дате
        trackers = dateFilter.filterTrackersByDay(trackers, date: date)
        print("📅 [FiltersViewModel] После фильтрации по дню недели (\(date)): \(trackers.map { $0.name })")

        // 2️⃣ Фильтр по выполнению / индексу
        trackers = dateFilter.filterTrackersByIndex(
            trackers,
            selectedFilterIndex: selectedFilterIndex,
            currentDate: date,
            searchText: searchText,
            completionChecker: isCompletedProvider
        )
        print("✅ [FiltersViewModel] После фильтрации по индексу \(selectedFilterIndex): \(trackers.map { $0.name })")

        // 3️⃣ (опционально) Фильтр по категории
        trackers = trackers.filter { tracker in
            // Можно добавить кастомный фильтр по категории, если нужно
            true
        }
        print("🏷 [FiltersViewModel] После фильтрации по категориям (если есть кастомные фильтры): \(trackers.map { $0.name })")

        filteredTrackers = trackers
        onFilteredTrackersUpdated?()
    }
    
    func selectFilter(index: Int) {
        selectedFilterIndex = index
    }
}
