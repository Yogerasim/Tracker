import UIKit

final class NewCategoryViewModel {

    // Входящие данные
    var categoryName: String = "" {
        didSet { validateCategoryName() }
    }

    // Выходящие события
    var isButtonEnabled: ((Bool) -> Void)?
    var onCategoryCreated: ((String) -> Void)?

    private func validateCategoryName() {
        let hasText = !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        isButtonEnabled?(hasText)
    }

    func saveCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        onCategoryCreated?(trimmedName)
    }
}
