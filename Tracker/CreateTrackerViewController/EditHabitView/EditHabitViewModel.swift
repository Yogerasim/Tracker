import CoreData
import UIKit
final class EditHabitViewModel {
    private(set) var tracker: TrackerCoreData
    private let context: NSManagedObjectContext
    private let recordStore: TrackerRecordStore
    var name: String {
        didSet {
            isButtonEnabled?(!name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
    var selectedEmoji: String
    var selectedColor: UIColor
    var selectedCategory: TrackerCategoryCoreData
    var selectedDays: [WeekDay]
    var isButtonEnabled: ((Bool) -> Void)?
    var onHabitEdited: (() -> Void)?
    init?(
        tracker: TrackerCoreData,
        context: NSManagedObjectContext,
        recordStore: TrackerRecordStore
    ) {
        guard let name = tracker.name,
              let emoji = tracker.emoji,
              let colorHex = tracker.color,
              let category = tracker.category
        else {
            return nil
        }
        self.tracker = tracker
        self.context = context
        self.recordStore = recordStore
        self.name = name
        self.selectedEmoji = emoji
        self.selectedColor = UIColor(hex: colorHex)
        self.selectedCategory = category
        if let data = tracker.schedule as? Data,
           let decoded = try? JSONDecoder().decode([WeekDay].self, from: data)
        {
            selectedDays = decoded
        } else {
            selectedDays = []
        }
    }
    var completedDaysCount: Int {
        recordStore.completedTrackers.filter { $0.trackerId == tracker.id }.count
    }
    func saveChanges() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        tracker.name = trimmed
        tracker.emoji = selectedEmoji
        tracker.color = selectedColor.toHexString()
        tracker.category = selectedCategory
        if let encoded = try? JSONEncoder().encode(selectedDays) {
            tracker.schedule = encoded as NSData
        }
        do {
            try context.save()
            onHabitEdited?()
        } catch {
            print("❌ EditHabitViewModel: failed to save tracker:", error)
        }
    }
}
