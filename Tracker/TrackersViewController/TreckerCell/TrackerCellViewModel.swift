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
        print("🧩 toggleCompletion for \(tracker.name), id: \(tracker.id)")

        // Получаем TrackerCoreData из viewContext через recordStore
        guard let trackerCoreData = recordStore.fetchTracker(by: tracker.id) else {
            print("❌ Tracker not found in CoreData")
            return
        }
        
        let dayStart = Calendar.current.startOfDay(for: currentDate)
        
        if isCompleted {
            // Удаляем запись
            if let record = trackerCoreData.records?.first(where: { ($0 as? TrackerRecordCoreData)?.date == dayStart }) as? TrackerRecordCoreData {
                recordStore.viewContext.delete(record)
                print("🗑 Removed record for \(tracker.name) | \(dayStart)")
            } else {
                print("⚠️ No record found to delete for \(tracker.name) | \(dayStart)")
            }
            isCompleted = false
            daysCount -= 1
        } else {
            // Добавляем запись
            let record = TrackerRecordCoreData(context: recordStore.viewContext)
            record.tracker = trackerCoreData
            record.date = dayStart
            print("➕ Added record for \(tracker.name) | \(dayStart)")
            
            isCompleted = true
            daysCount += 1
        }
        
        // Сохраняем viewContext сразу
        do {
            if recordStore.viewContext.hasChanges {
                try recordStore.viewContext.save()
                print("💾 viewContext saved successfully")
            }
        } catch {
            print("❌ Failed to save viewContext: \(error)")
        }
        
        // UI и уведомления
        onStateChanged?()
        NotificationCenter.default.post(name: .trackerRecordsDidChange, object: tracker)
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
