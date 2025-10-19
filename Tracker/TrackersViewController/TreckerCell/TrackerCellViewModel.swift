import Foundation
import UIKit

final class TrackerCellViewModel {
    
    // MARK: - Dependencies
    var tracker: Tracker
    private let recordStore: TrackerRecordStore
    
    
    // MARK: - State
    private(set) var isCompleted: Bool
    private(set) var daysCount: Int
    var currentDate: Date
    
    // MARK: - Callbacks
    var onStateChanged: (() -> Void)?
    
    // MARK: - Init
    init(tracker: Tracker, recordStore: TrackerRecordStore, currentDate: Date = Date()) {
        self.tracker = tracker
        self.recordStore = recordStore
        self.currentDate = currentDate
        
        if let trackerCoreData = recordStore.fetchTracker(by: tracker.id) {
            self.isCompleted = recordStore.isCompleted(for: trackerCoreData, date: currentDate)
        } else {
            self.isCompleted = false
        }
        
        self.daysCount = recordStore.completedTrackers.filter { $0.trackerId == tracker.id }.count
    }
    
    // MARK: - Actions
    func toggleCompletion() {
        guard let trackerCoreData = recordStore.fetchTracker(by: tracker.id) else { return }
        
        if isCompleted {
            isCompleted = false
            daysCount -= 1
            recordStore.removeRecord(for: trackerCoreData, date: currentDate)
        } else {
            isCompleted = true
            daysCount += 1
            recordStore.addRecord(for: trackerCoreData, date: currentDate)
            
        }
        NotificationCenter.default.post(name: .trackerRecordsDidChange, object: tracker)
        onStateChanged?()
    }
    
    func refreshState() {
        guard recordStore.fetchTracker(by: tracker.id) != nil else {
            isCompleted = false
            daysCount = 0
            onStateChanged?()
            return
        }
        
        isCompleted = recordStore.completedTrackers.contains(where: { $0.trackerId == tracker.id })
        daysCount = recordStore.completedTrackers.filter { $0.trackerId == tracker.id }.count
        onStateChanged?()
    }
    func refreshStateIfNeeded() {
        if recordStore.fetchTracker(by: tracker.id) != nil {
            self.daysCount = recordStore.completedTrackers.filter { $0.trackerId == tracker.id }.count
        } else {
            self.daysCount = 0
        }
        onStateChanged?()
    }
    func isTrackerCompletedEver(_ trackerId: UUID) -> Bool {
        recordStore.completedTrackers.contains { $0.trackerId == trackerId }
    }
    
    // MARK: - UI Helpers
    func dayLabelText() -> String {
        String.localizedStringWithFormat(
            NSLocalizedString("days_count", comment: "Number of days tracker completed"),
            daysCount
        )
    }
    
    func buttonSymbol() -> String {
        isCompleted ? "checkmark" : "plus"
    }
    func updateCurrentDate(_ date: Date) {
        self.currentDate = date
        refreshState()
    }
    
    func trackerEmoji() -> String { tracker.emoji }
    func trackerTitle() -> String { tracker.name }
    func trackerColor() -> UIColor { UIColor(hex: tracker.color) }
}
