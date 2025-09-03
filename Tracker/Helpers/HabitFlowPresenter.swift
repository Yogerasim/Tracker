import Foundation

final class HabitFlowPresenter {

    private let categoryStore: TrackerCategoryStore
    private let defaultCategoryTitle = "Мои трекеры"

    init(categoryStore: TrackerCategoryStore) {
        self.categoryStore = categoryStore
    }

    /// Добавляет трекер в категорию по умолчанию
    func addTracker(_ tracker: Tracker, completion: @escaping () -> Void) {
        ensureDefaultCategory()
        categoryStore.addTracker(tracker, to: defaultCategoryTitle)
        print("📌 Трекер '\(tracker.name)' добавлен в категорию '\(defaultCategoryTitle)'")
        DispatchQueue.main.async {
            completion()
        }
    }

    private func ensureDefaultCategory() {
        if !categoryStore.categories.contains(where: { $0.title == defaultCategoryTitle }) {
            categoryStore.addCategory(
                TrackerCategory(title: defaultCategoryTitle, trackers: [])
            )
            print("📂 Создана категория по умолчанию '\(defaultCategoryTitle)'")
        }
    }
}
