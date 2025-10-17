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
        let categoryVC = CategoryViewController(store: categoryStore)
        let categoryVM = CategoryViewModel<TrackerCategoryCoreData>(store: categoryStore)

        categoryVM.onCategorySelected = { category in
            tableView.reloadRows(at: [indexPath], with: .automatic)
            onCategorySelected(category)
        }
        
        viewController.present(categoryVC, animated: true)
    }
}
