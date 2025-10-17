import Foundation
import CoreData

final class EditCategoryViewModel {

    private let category: TrackerCategoryCoreData
    private let context: NSManagedObjectContext

    var categoryName: String {
        didSet {
            isButtonEnabled?( !categoryName.trimmingCharacters(in: .whitespaces).isEmpty )
        }
    }

    var isButtonEnabled: ((Bool) -> Void)?
    var onCategoryEdited: (() -> Void)?

    init(category: TrackerCategoryCoreData, context: NSManagedObjectContext) {
        self.category = category
        self.context = context
        self.categoryName = category.title ?? ""
    }

    func saveChanges() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        category.title = trimmedName

        do {
            try context.save()
            onCategoryEdited?()
            print("✏️ Категория обновлена: \(trimmedName)")
        } catch {
            print("❌ Ошибка при сохранении изменений категории: \(error)")
        }
    }
}
