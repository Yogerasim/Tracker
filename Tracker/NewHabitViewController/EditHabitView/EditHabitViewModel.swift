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
        // используем твой UIColor(hex:) конструктор
        self.selectedColor = UIColor(hex: colorHex)
        self.selectedCategory = category
        
        // Декодируем расписание прямо здесь — если расширение недоступно
        if let scheduleData = tracker.schedule as? Data,
           let decoded = try? JSONDecoder().decode([WeekDay].self, from: scheduleData) {
            self.selectedDays = decoded
        } else {
            self.selectedDays = []
        }
    }
    
    func saveChanges() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        tracker.name = trimmedName
        tracker.emoji = selectedEmoji
        tracker.color = selectedColor.toHexString() // остаётся преобразование в hex
        tracker.category = selectedCategory
        
        // Кодируем selectedDays обратно в tracker.schedule (NSData)
        if let encoded = try? JSONEncoder().encode(selectedDays) {
            tracker.schedule = encoded as NSData
        } else {
            // Если не удалось закодировать (маловероятно) — записываем пустой массив
            tracker.schedule = (try? JSONEncoder().encode([WeekDay]())) as NSData?
        }
        
        do {
            try context.save()
            print("✏️ Трекер обновлён: \(trimmedName)")
            onHabitEdited?()
        } catch {
            print("❌ Ошибка сохранения изменений трекера: \(error)")
        }
    }
}
