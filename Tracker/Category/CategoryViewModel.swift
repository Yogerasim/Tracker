import Foundation

final class CategoryViewModel {
    var titleText: String { "Категория" }
    var placeholderText: String { "Привычки и события можно\nобъединить по смыслу" }
    var buttonTitle: String { "Добавить категорию" }

    private(set) var categories: [String] = [] {
        didSet { onCategoriesChanged?(categories) }
    }

    var onCategoriesChanged: (([String]) -> Void)?
    var onCategorySelected: ((String) -> Void)?
    var onShowNewCategory: (() -> Void)?

    func loadCategories() {
        categories = []
    }

    func addCategoryTapped() {
        onShowNewCategory?()
    }

    func selectCategory(_ category: String) {
        onCategorySelected?(category)
    }
}
