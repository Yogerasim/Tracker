import Foundation

final class CategoryViewModel {

    private let categoryStore: TrackerCategoryStore

    // MARK: - Bindings
    var onCategoriesChanged: (([TrackerCategory]) -> Void)?
    var onCategorySelected: ((TrackerCategoryCoreData) -> Void)?
    var onShowNewCategory: (() -> Void)?

    // MARK: - Data
    private(set) var categories: [TrackerCategory] = [] {
        didSet { onCategoriesChanged?(categories) }
    }

    init(store: TrackerCategoryStore) {
        self.categoryStore = store
        self.categoryStore.delegate = self
        loadCategories()
    }

    // MARK: - Methods
    func loadCategories() {
        categories = categoryStore.categories
    }

    func addCategoryTapped() {
        onShowNewCategory?()
    }

    func selectCategory(at index: Int) {
        guard index < categories.count else { return }
        let category = categories[index]
        
        // Преобразуем в CoreData
        let coreDataCategory = TrackerCategoryCoreData(context: CoreDataStack.shared.context)
        coreDataCategory.id = category.id
        coreDataCategory.title = category.title
        
        onCategorySelected?(coreDataCategory)
    }

    func add(_ category: TrackerCategory) {
        categoryStore.add(category)
    }

    // UITableView helpers
    var numberOfRows: Int { categories.count }

    func categoryName(at index: Int) -> String {
        guard index < categories.count else { return "" }
        return categories[index].title
    }
}

// MARK: - TrackerCategoryStoreDelegate
extension CategoryViewModel: TrackerCategoryStoreDelegate {
    func didUpdateCategories() {
        loadCategories() 
    }
}
