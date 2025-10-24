import Foundation
import Combine

final class FiltersViewModel {
    
    // MARK: - State
    @Published private(set) var filteredTrackers: [Tracker] = []
    @Published var selectedFilterIndex: Int = 0 {
        didSet { applyFilter() }
    }
    
    var searchText: String = "" {
        didSet { applyFilter() }
    }
    
    private let trackersProvider: () -> [Tracker]
    private let currentDateProvider: () -> Date
    private let isCompletedProvider: (Tracker, Date) -> Bool
    private let dateFilter: TrackersDateFilter
    
    var onFilteredTrackersUpdated: (() -> Void)?
    
    init(trackersProvider: @escaping () -> [Tracker],
         currentDateProvider: @escaping () -> Date,
         isCompletedProvider: @escaping (Tracker, Date) -> Bool,
         dateFilter: TrackersDateFilter) {
        
        self.trackersProvider = trackersProvider
        self.currentDateProvider = currentDateProvider
        self.isCompletedProvider = isCompletedProvider
        self.dateFilter = dateFilter
    }
    
    func applyFilter() {
        let trackers = trackersProvider()
        let currentDate = currentDateProvider()
        filteredTrackers = dateFilter.filterTrackers(
            trackers,
            selectedFilterIndex: selectedFilterIndex,
            currentDate: currentDate,
            searchText: searchText,
            completionChecker: isCompletedProvider
        )
        onFilteredTrackersUpdated?()
    }
    
    func selectFilter(index: Int) {
        selectedFilterIndex = index
    }
}
