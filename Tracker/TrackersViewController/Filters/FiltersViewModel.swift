import Combine
import Foundation

final class FiltersViewModel {
    @Published private(set) var filteredTrackers: [Tracker] = []
    @Published var selectedFilterIndex: Int = 0
    @Published var selectedDate: Date = .init()
    @Published var searchText: String = ""
    var selectedCategory: TrackerCategory?
    var onFilteredTrackersUpdated: (() -> Void)?
    private let trackersProvider: () -> [Tracker]
    private let isCompletedProvider: (Tracker, Date) -> Bool
    private let dateFilter: TrackersDateFilter
    private let calendar = Calendar.current
    private var cancellables = Set<AnyCancellable>()
    private var hasInitialDataLoaded = false
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

    func applyAllFilters(for date: Date) {
        var trackers = trackersProvider()
        trackers = dateFilter.filterTrackersByDay(trackers, date: date)
        trackers = dateFilter.filterTrackersByIndex(
            trackers,
            selectedFilterIndex: selectedFilterIndex,
            currentDate: date,
            searchText: searchText,
            completionChecker: isCompletedProvider
        )
        trackers = trackers.filter { _ in true }
        if trackers.map({ $0.id }) != filteredTrackers.map({ $0.id }) {
            filteredTrackers = trackers
            onFilteredTrackersUpdated?()
        } else {}
    }

    func selectFilter(index: Int) {
        selectedFilterIndex = index
    }
}
