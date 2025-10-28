import Foundation
import UIKit

final class TrackerCellViewModel {
    
    
    var tracker: Tracker
    private let recordStore: TrackerRecordStore
    
    
    private(set) var isCompleted: Bool
    private(set) var daysCount: Int
    var currentDate: Date
    
    
    var onStateChanged: (() -> Void)?
    
    
    init(tracker: Tracker, recordStore: TrackerRecordStore, currentDate: Date = Date()) {
        self.tracker = tracker
        self.recordStore = recordStore
        self.currentDate = currentDate
        
        if let trackerCoreData = recordStore.fetchTrackerInViewContext(by: tracker.id) {
            self.isCompleted = recordStore.isCompleted(for: trackerCoreData, date: currentDate)
        } else {
            self.isCompleted = false
        }
        
        self.daysCount = recordStore.completedTrackers.filter { $0.trackerId == tracker.id }.count
    }
    
    
    func toggleCompletion() {
        AppLogger.trackers.info("[VM] 🌀 toggleCompletion for \(tracker.name) (oldState: \(isCompleted))")
        
        let oldState = isCompleted
        isCompleted.toggle()
        daysCount += isCompleted ? 1 : -1
        onStateChanged?()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            if oldState {
                AppLogger.trackers.info("[VM] 🗑 deleteRecord for \(self.tracker.name)")
                self.recordStore.deleteRecord(for: self.tracker.id, date: self.currentDate)
            } else {
                AppLogger.trackers.info("[VM] 💾 addRecord for \(self.tracker.name)")
                if let trackerCore = self.recordStore.fetchTrackerInViewContext(by: self.tracker.id) {
                    self.recordStore.addRecord(for: trackerCore, date: self.currentDate)
                } else {
                    self.recordStore.addRecord(for: self.tracker.id, date: self.currentDate)
                }
            }

            DispatchQueue.main.async {
                AppLogger.trackers.info("[VM] 📡 post trackerRecordsDidChange for \(self.tracker.name)")
                NotificationCenter.default.post(name: .trackerRecordsDidChange, object: self.tracker)
            }
        }
    }
    
    func refreshState() {
        guard recordStore.fetchTrackerInViewContext(by: tracker.id) != nil else {
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
        if recordStore.fetchTrackerInViewContext(by: tracker.id) != nil {
            self.daysCount = recordStore.completedTrackers.filter { $0.trackerId == tracker.id }.count
        } else {
            self.daysCount = 0
        }
        onStateChanged?()
    }
    
    func isTrackerCompletedEver(_ trackerId: UUID) -> Bool {
        recordStore.completedTrackers.contains { $0.trackerId == trackerId }
    }
    
    
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
