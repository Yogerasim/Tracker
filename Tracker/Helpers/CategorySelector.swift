import UIKit

final class CategorySelector {

    static func presentCategorySelector(
        from viewController: UIViewController,
        tableView: UITableView,
        indexPath: IndexPath,
        onCategorySelected: @escaping (TrackerCategoryCoreData) -> Void
    ) {
        let coreDataStack = CoreDataStack.shared
        let categoryStore = TrackerCategoryStore(context: coreDataStack.context)
        let categoryVM = CategoryViewModel(store: categoryStore)
        let categoryVC = CategoryViewController(store: categoryStore)

        categoryVM.onCategorySelected = { category in
            // category уже должен быть TrackerCategoryCoreData
            guard let coreDataCategory = category as? TrackerCategoryCoreData else {
                assertionFailure("Category должен быть CoreData объектом")
                return
            }
            tableView.reloadRows(at: [indexPath], with: .automatic)
            onCategorySelected(coreDataCategory)
        }

        viewController.present(categoryVC, animated: true)
    }
}
