import Foundation
import CoreData
import UIKit

final class EditHabitViewModel {

    private(set) var tracker: TrackerCoreData
    private let context: NSManagedObjectContext

    var name: String {
        didSet {
            isButtonEnabled?( !name.trimmingCharacters(in: .whitespaces).isEmpty )
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
        self.selectedEmoji = emoji
        self.selectedColor = UIColor(hex: colorHex) // используем твой UIColor(hex:)
        self.selectedCategory = category
        self.selectedDays = tracker.decodedSchedule
    }

    func saveChanges() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        tracker.name = trimmedName
        tracker.emoji = selectedEmoji
        tracker.color = selectedColor.toHexString() // оставляем метод преобразования в hex, его можно оставить в отдельном UIColor+Hex файле
        tracker.category = selectedCategory
        tracker.decodedSchedule = selectedDays

        do {
            try context.save()
            print("✏️ Трекер обновлён: \(trimmedName)")
            onHabitEdited?()
        } catch {
            print("❌ Ошибка сохранения изменений трекера: \(error)")
        }
    }
}


