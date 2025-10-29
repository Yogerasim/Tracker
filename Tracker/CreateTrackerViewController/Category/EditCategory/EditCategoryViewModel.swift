import CoreData
import Foundation

final class EditCategoryViewModel {
    private let category: TrackerCategoryCoreData
    private let context: NSManagedObjectContext
    var categoryName: String {
        didSet {
            isButtonEnabled?(!categoryName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    var isButtonEnabled: ((Bool) -> Void)?
    var onCategoryEdited: (() -> Void)?
    init(category: TrackerCategoryCoreData, context: NSManagedObjectContext) {
        self.category = category
        self.context = context
        categoryName = category.title ?? ""
    }

    func saveChanges() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        category.title = trimmedName
        do {
            try context.save()
            onCategoryEdited?()
        } catch {}
    }
}
