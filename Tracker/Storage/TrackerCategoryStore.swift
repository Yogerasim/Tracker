import UIKit

final class TrackerCategoryStore {
    private(set) var categories: [TrackerCategory] = []

    func addCategory(_ category: TrackerCategory) {
        categories.append(category)
        print("✅ Добавлена категория: \(category.title)")
    }

    func addTracker(_ tracker: Tracker, to categoryTitle: String) {
        guard let index = categories.firstIndex(where: { $0.title == categoryTitle }) else {
            print("⚠️ Категория '\(categoryTitle)' не найдена")
            return
        }

        let category = categories[index]
        let newCategory = TrackerCategory(
            title: category.title,
            trackers: category.trackers + [tracker]
        )
        categories[index] = newCategory

        print("📌 Трекер '\(tracker.name)' добавлен в категорию '\(categoryTitle)'")
    }
}

