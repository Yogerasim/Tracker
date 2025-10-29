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

        // 1️⃣ Фильтр по дате
        trackers = dateFilter.filterTrackersByDay(trackers, date: date)

        // 2️⃣ Фильтр по выполнению / индексу
        trackers = dateFilter.filterTrackersByIndex(
            trackers,
            selectedFilterIndex: selectedFilterIndex,
            currentDate: date,
            searchText: searchText,
            completionChecker: isCompletedProvider
        )

        // 3️⃣ (опционально) Фильтр по категории
        trackers = trackers.filter { tracker in
            // Можно добавить кастомный фильтр по категории, если нужно
            true
        }

        filteredTrackers = trackers
        onFilteredTrackersUpdated?()
    }
    
    func selectFilter(index: Int) {
        selectedFilterIndex = index
    }
}
