import Foundation
import UIKit

final class TrackerCellViewModel {
    // MARK: - Properties

    var tracker: Tracker
    private let recordStore: TrackerRecordStore

    /// ✅ computed — состояние всегда читается из CoreData, больше нет локального дубля
    var isCompleted: Bool {
        guard let cd = recordStore.fetchTrackerInViewContext(by: tracker.id) else { return false }
        return recordStore.isCompleted(for: cd, date: currentDate)
    }

    /// ✅ daysCount тоже нужно всегда вычислять, иначе он рассинхронизируется
    var daysCount: Int {
        recordStore.completedTrackers.filter { $0.trackerId == tracker.id }.count
    }

    var currentDate: Date
    var onStateChanged: (() -> Void)?

    // MARK: - Init

    init(tracker: Tracker, recordStore: TrackerRecordStore, currentDate: Date = Date()) {
        self.tracker = tracker
        self.recordStore = recordStore
        self.currentDate = currentDate
    }

    // MARK: - Public

    func toggleCompletion() {
        AppLogger.trackers.info("[CellVM] toggleCompletion called for tracker: \(tracker.name) (\(tracker.id))")

        let wasCompleted = isCompleted

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            if wasCompleted {
                AppLogger.trackers.info("[CellVM] Removing record for \(self.tracker.name) on \(self.currentDate.short)")
                self.recordStore.deleteRecord(for: self.tracker.id, date: self.currentDate)
            } else {
                AppLogger.trackers.info("[CellVM] Adding record for \(self.tracker.name) on \(self.currentDate.short)")
                if let cd = self.recordStore.fetchTrackerInViewContext(by: self.tracker.id) {
                    self.recordStore.addRecord(for: cd, date: self.currentDate)
                } else {
                    self.recordStore.addRecord(for: self.tracker.id, date: self.currentDate)
                }
            }

            DispatchQueue.main.async {
                AppLogger.trackers.info("[CellVM] Posting trackerRecordsDidChange for \(self.tracker.name)")
                

                // ✅ UI обновится после записи в CoreData
                self.onStateChanged?()
            }
        }
    }

    /// ✅ Просто говорит UI обновиться на основании свежих данных
    func refreshState() {
        onStateChanged?()
    }

    /// ✅ Теперь идентичен refreshState — локального состояния больше нет
    func refreshStateIfNeeded() {
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
        currentDate = date
        refreshState()
    }

    // MARK: - Convenience

    func trackerEmoji() -> String { tracker.emoji }
    func trackerTitle() -> String { tracker.name }
    func trackerColor() -> UIColor { UIColor(hex: tracker.color) }
}
