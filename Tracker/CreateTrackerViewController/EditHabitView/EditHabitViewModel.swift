import CoreData
import UIKit
final class EditHabitViewModel {
    private(set) var tracker: TrackerCoreData
    private let context: NSManagedObjectContext
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
    init?(tracker: TrackerCoreData, context: NSManagedObjectContext) {
        guard let name = tracker.name,
              let emoji = tracker.emoji,
              let colorHex = tracker.color,
              let category = tracker.category else { return nil }
        self.tracker = tracker
        self.context = context
        self.name = name
        selectedEmoji = emoji
        selectedColor = UIColor(hex: colorHex)
        selectedCategory = category
        if let scheduleData = tracker.schedule as? Data,
           let decoded = try? JSONDecoder().decode([WeekDay].self, from: scheduleData)
        {
            selectedDays = decoded
        } else {
            selectedDays = []
        }
    }
    func saveChanges() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        tracker.name = trimmedName
        tracker.emoji = selectedEmoji
        tracker.color = selectedColor.toHexString()
        tracker.category = selectedCategory
        if let encoded = try? JSONEncoder().encode(selectedDays) {
            tracker.schedule = encoded as NSData
        } else {
            tracker.schedule = (try? JSONEncoder().encode([WeekDay]())) as NSData?
        }
        do {
            try context.save()
            onHabitEdited?()
        } catch {}
    }
}
