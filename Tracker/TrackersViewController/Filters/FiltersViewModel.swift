import Foundation
import Combine

final class FiltersViewModel {
    
    // MARK: - State
    @Published private(set) var filteredTrackers: [Tracker] = []
    @Published var selectedFilterIndex: Int = 0 {
        didSet { applyFilter() }
    }
    
    private let trackersProvider: () -> [Tracker]
    private let currentDateProvider: () -> Date
    private let isCompletedProvider: (Tracker, Date) -> Bool
    
    // MARK: - Callbacks
    var onFilteredTrackersUpdated: (() -> Void)?
    
    // MARK: - Init
    init(trackersProvider: @escaping () -> [Tracker],
         currentDateProvider: @escaping () -> Date,
         isCompletedProvider: @escaping (Tracker, Date) -> Bool) {
        self.trackersProvider = trackersProvider
        self.currentDateProvider = currentDateProvider
        self.isCompletedProvider = isCompletedProvider
    }
    
    // MARK: - Filtering
    private func applyFilter() {
        let allTrackers = trackersProvider()
        let currentDate = currentDateProvider()
        
        switch selectedFilterIndex {
        case 0: // Все трекеры
            filteredTrackers = allTrackers
        case 1: // На сегодня
            filteredTrackers = allTrackers.filter { $0.schedule.contains(currentDate.weekDay) }
        case 2: // Завершенные
            filteredTrackers = allTrackers.filter { isCompletedProvider($0, currentDate) }
        case 3: // Не завершенные
            filteredTrackers = allTrackers.filter { !isCompletedProvider($0, currentDate) }
        default:
            filteredTrackers = allTrackers
        }
        
        onFilteredTrackersUpdated?()
    }
    
    func selectFilter(index: Int) {
        selectedFilterIndex = index
    }
}
