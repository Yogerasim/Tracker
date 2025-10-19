import Foundation
import UIKit

final class TrackerCellViewModel {
    
    // MARK: - Dependencies
    private let tracker: Tracker
    private let recordStore: TrackerRecordStore
    private let currentDate: Date
    
    // MARK: - State
    private(set) var isCompleted: Bool
    private(set) var daysCount: Int
    
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
        if let trackerCoreData = recordStore.fetchTracker(by: tracker.id) {
            self.isCompleted = recordStore.isCompleted(for: trackerCoreData, date: currentDate)
            print("🔄 [TrackerCellViewModel] refreshState — tracker: \(tracker.name), isCompleted = \(self.isCompleted)")
            self.daysCount = recordStore.completedTrackers.filter { $0.trackerId == tracker.id }.count
        } else {
            self.isCompleted = false
            self.daysCount = 0
            print("🔄 [TrackerCellViewModel] refreshState — tracker: \(tracker.name), NOT FOUND in CoreData")
        }
        onStateChanged?()
    }
    func refreshStateIfNeeded() {
        // Обновляем только количество дней, но не isCompleted
        if recordStore.fetchTracker(by: tracker.id) != nil {
            self.daysCount = recordStore.completedTrackers.filter { $0.trackerId == tracker.id }.count
        } else {
            self.daysCount = 0
        }
        onStateChanged?()
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
    
    func trackerEmoji() -> String { tracker.emoji }
    func trackerTitle() -> String { tracker.name }
    func trackerColor() -> UIColor { UIColor(hex: tracker.color) }
}
