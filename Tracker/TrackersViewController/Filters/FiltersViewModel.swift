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
        print("🔵 [FiltersVM] applyFilter called — selectedFilterIndex = \(selectedFilterIndex)")

        let allTrackers = trackersProvider()
        let currentDate = currentDateProvider()
        print("🔵 [FiltersVM] allTrackers.count = \(allTrackers.count), currentDate = \(currentDate)")

        switch selectedFilterIndex {
        case 0:
            filteredTrackers = allTrackers
        case 1:
            filteredTrackers = allTrackers.filter {
                let passes = $0.schedule.contains(currentDate.weekDay)
                print("   ◼️ '\($0.name)' schedule contains day? \(passes) schedule=\($0.schedule)")
                return passes
            }
        case 2:
            filteredTrackers = allTrackers.filter {
                let completed = isCompletedProvider($0, currentDate)
                print("   ✅ '\($0.name)' completed on \(currentDate): \(completed)")
                return completed
            }
        case 3:
            filteredTrackers = allTrackers.filter {
                let completed = isCompletedProvider($0, currentDate)
                print("   ❌ '\($0.name)' completed on \(currentDate): \(completed) -> include = \(!completed)")
                return !completed
            }
        default:
            filteredTrackers = allTrackers
        }

        print("🔵 [FiltersVM] filteredTrackers.count = \(filteredTrackers.count) names = \(filteredTrackers.map { $0.name })")
        onFilteredTrackersUpdated?()
    }
    
    func selectFilter(index: Int) {
        selectedFilterIndex = index
    }
}
