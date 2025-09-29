import Foundation
final class NewCategoryViewModel {

    private let store: TrackerCategoryStore
    var categoryName: String = "" {
        didSet { isButtonEnabled?( !categoryName.trimmingCharacters(in: .whitespaces).isEmpty ) }
    }

    // MARK: - Bindings
    var isButtonEnabled: ((Bool) -> Void)?
    var onCategoryCreated: ((TrackerCategory) -> Void)?
    
    init(store: TrackerCategoryStore) {
        self.store = store
    }

    // MARK: - Save
    func saveCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        let category = TrackerCategory(id: UUID(), title: trimmedName, trackers: [])
        store.add(category)            // сохраняем в Core Data
        onCategoryCreated?(category)   // уведомляем контроллер
    }
}
