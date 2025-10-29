import Foundation

final class NewCategoryViewModel {
    private let store: TrackerCategoryStore
    var categoryName: String = "" {
        didSet {
            let enabled = !categoryName.trimmingCharacters(in: .whitespaces).isEmpty
            isButtonEnabled?(enabled)
        }
    }

    var isButtonEnabled: ((Bool) -> Void)?
    var onCategoryCreated: ((TrackerCategory) -> Void)?
    init(store: TrackerCategoryStore) {
        self.store = store
    }

    func saveCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        let category = TrackerCategory(id: UUID(), title: trimmedName, trackers: [])
        store.add(category)
        onCategoryCreated?(category)
    }
}
