final class CategoryViewModel {

    private let categoryStore: TrackerCategoryStore

    // MARK: - Bindings
    var onCategoriesChanged: (([TrackerCategoryCoreData]) -> Void)?
    var onCategorySelected: ((TrackerCategoryCoreData) -> Void)?

    // MARK: - Data
    private(set) var categories: [TrackerCategoryCoreData] = [] {
        didSet { onCategoriesChanged?(categories) }
    }

    init(store: TrackerCategoryStore) {
        self.categoryStore = store
        self.categoryStore.delegate = self
        loadCategories()
    }

    func loadCategories() {
        categories = categoryStore.fetchCategories() // возвращает [TrackerCategoryCoreData]
    }

    func selectCategory(at index: Int) {
        guard index < categories.count else { return }
        let selectedCategory = categories[index]
        onCategorySelected?(selectedCategory)
    }

    func add(_ category: TrackerCategoryCoreData) {
        categoryStore.add(category)
    }

    var numberOfRows: Int { categories.count }

    func categoryName(at index: Int) -> String {
        guard index < categories.count else { return "" }
        return categories[index].title ?? ""
    }
}

extension CategoryViewModel: TrackerCategoryStoreDelegate {
    func didUpdateCategories() {
        loadCategories()
    }
}
