import UIKit

final class NewHabitView: TrackerCreationViewModel {
    init() {
        super.init(title: NSLocalizedString("new_habit.title", comment: "Новая привычка"))
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { nil }
    override func createTapped() {
        guard !selectedDays.isEmpty else {
            return enableCreateButton()
        }
        createTracker(with: selectedDays)
    }

    override func numberOfRowsInTable() -> Int { 2 }
    override func tableViewCell(for tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContainerTableViewCell
        if indexPath.row == 0 {
            cell.configure(
                title: NSLocalizedString("new_habit.category", comment: ""),
                detail: selectedCategory?.title ?? ""
            )
        } else {
            let detailText = selectedDays.isEmpty ? nil : selectedDays.descriptionText
            cell.configure(
                title: NSLocalizedString("new_habit.schedule", comment: ""),
                detail: detailText
            )
        }
        cell.isLastCell = indexPath.row == numberOfRowsInTable() - 1
        return cell
    }

    override func didSelectRow(at indexPath: IndexPath, tableView: UITableView) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            let store = TrackerCategoryStore(context: context)
            let vc = CategoryViewController(store: store)
            vc.onCategorySelected = { [weak self] (category: TrackerCategoryCoreData) in
                self?.selectedCategory = category
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            presentFullScreenSheet(vc)
        } else if indexPath.row == 1 {
            let scheduleVC = ScheduleViewController()
            scheduleVC.selectedDays = selectedDays
            scheduleVC.onDone = { [weak self] days in
                self?.selectedDays = days
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            presentFullScreenSheet(scheduleVC)
        }
    }
}
