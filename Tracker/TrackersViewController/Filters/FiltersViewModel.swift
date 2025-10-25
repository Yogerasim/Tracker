import Foundation
import Combine

final class FiltersViewModel {
    
    @Published private(set) var filteredTrackers: [Tracker] = []
    @Published var selectedFilterIndex: Int = 0 { didSet { applyFilter() } }
    @Published var selectedDate: Date = Date() { didSet { applyFilter() } }
    var searchText: String = "" { didSet { applyFilter() } }
    
    private let trackersProvider: () -> [Tracker]
    private let isCompletedProvider: (Tracker, Date) -> Bool
    private let dateFilter: TrackersDateFilter
    var onFilteredTrackersUpdated: (() -> Void)?
    
    init(trackersProvider: @escaping () -> [Tracker],
         isCompletedProvider: @escaping (Tracker, Date) -> Bool,
         dateFilter: TrackersDateFilter) {
        self.trackersProvider = trackersProvider
        self.isCompletedProvider = isCompletedProvider
        self.dateFilter = dateFilter
    }
    
    func applyFilter(for date: Date? = nil) {
        let trackers = trackersProvider()
        let currentDate = date ?? selectedDate
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
