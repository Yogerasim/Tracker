import Foundation

final class HabitFlowPresenter {
    
    private let categoryStore: TrackerCategoryStore
    private let defaultCategoryTitle = NSLocalizedString(
        "default_category_title",
        comment: "Название категории по умолчанию для трекеров"
    )
    
    init(categoryStore: TrackerCategoryStore) {
        self.categoryStore = categoryStore
    }
    
    
    func addTracker(_ tracker: Tracker, completion: @escaping () -> Void) {
        // ⚠️ Не создаём категорию автоматически
        if let _ = categoryStore.fetchCategories().first(where: { $0.title == defaultCategoryTitle }) {
            categoryStore.addTracker(tracker, to: defaultCategoryTitle)
            print("📌 Трекер '\(tracker.name)' добавлен в '\(defaultCategoryTitle)'")
        } else {
            print("⚠️ Категория '\(defaultCategoryTitle)' отсутствует, создайте вручную.")
        }
        DispatchQueue.main.async {
            completion()
        }
    }
    
    private func ensureDefaultCategory() {
        
        if !categoryStore.categories.contains(where: { $0.title == defaultCategoryTitle }) {
            
            let newCategory = TrackerCategory(
                id: UUID(),
                title: defaultCategoryTitle,
                trackers: []
            )
            categoryStore.add(newCategory)
            print("📂 Создана категория по умолчанию '\(defaultCategoryTitle)'")
        }
    }
}
