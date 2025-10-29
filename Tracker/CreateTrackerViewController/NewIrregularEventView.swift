import UIKit

final class NewIrregularEventView: TrackerCreationViewModel {
    init() {
        super.init(title: NSLocalizedString("new_irregular_event.title", comment: ""))
        tableContainer.updateHeight(forRows: 1)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { nil }
    override func createTapped() {
        createTracker(with: WeekDay.allCases)
    }

    override func numberOfRowsInTable() -> Int { 1 }
    override func tableViewCell(for tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContainerTableViewCell
        cell.configure(
            title: NSLocalizedString("new_irregular_event.category", comment: "Категория"),
            detail: selectedCategory?.title ?? ""
        )
        cell.isLastCell = true
        return cell
    }

    override func didSelectRow(at indexPath: IndexPath, tableView: UITableView) {
        tableView.deselectRow(at: indexPath, animated: true)
        let store = TrackerCategoryStore(context: context)
        let vc = CategoryViewController(store: store)
        vc.onCategorySelected = { [weak self] (category: TrackerCategoryCoreData) in
            self?.selectedCategory = category
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 16
        }
        present(vc, animated: true)
    }
}
