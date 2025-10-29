import UIKit

final class EditHabitViewController: BaseTrackerCreationViewController {
    private let viewModel: EditHabitViewModel
    private let daysCountLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.bold(32)
        label.textColor = AppColors.backgroundBlackButton
        label.textAlignment = .center
        return label
    }()

    init(viewModel: EditHabitViewModel) {
        self.viewModel = viewModel
        super.init(title: NSLocalizedString("edit_habit.title", comment: "Редактировать привычку"))
        selectedEmoji = viewModel.selectedEmoji
        selectedColor = viewModel.selectedColor
        selectedCategory = viewModel.selectedCategory
        selectedDays = viewModel.selectedDays
        nameTextField.setText(viewModel.name)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { nil }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDaysCountLabel()
        setupSaveButton()
        updateDaysCountLabel()
    }
}

private extension EditHabitViewController {
    func setupDaysCountLabel() {
        contentStack.insertArrangedSubview(daysCountLabel, at: 0)
        daysCountLabel.translatesAutoresizingMaskIntoConstraints = false
        daysCountLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        daysCountLabel.topAnchor.constraint(equalTo: contentStack.topAnchor, constant: -20).isActive = true
    }

    func setupSaveButton() {
        bottomButtons.createButton.setTitle(
            NSLocalizedString("edit_habit.save", comment: "Сохранить"),
            for: .normal
        )
        bottomButtons.createButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }

    func updateDaysCountLabel() {
        let count = selectedDays.count
        daysCountLabel.text = localizedDaysText(for: count)
    }

    func localizedDaysText(for count: Int) -> String {
        let localeIdentifier: String
        if #available(iOS 16.0, *) {
            localeIdentifier = Locale.current.language.languageCode?.identifier ?? "en"
        } else {
            localeIdentifier = Locale.current.languageCode ?? "en"
        }
        if localeIdentifier == "ru" {
            let nAbs = abs(count) % 100
            let n1 = nAbs % 10
            let key: String
            if nAbs > 10 && nAbs < 20 {
                key = "edit_habit.days_count.many"
            } else if n1 == 1 {
                key = "edit_habit.days_count.one"
            } else if n1 >= 2 && n1 <= 4 {
                key = "edit_habit.days_count.few"
            } else {
                key = "edit_habit.days_count.many"
            }
            let format = NSLocalizedString(key, comment: "Количество дней")
            return String(format: format, count)
        } else {
            let key = (count == 1)
                ? "edit_habit.days_count.one"
                : "edit_habit.days_count.other"
            let format = NSLocalizedString(key, comment: "Number of days")
            return String(format: format, count)
        }
    }
}

private extension EditHabitViewController {
    @objc func saveTapped() {
        let title = nameTextField.textValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        guard let emoji = selectedEmoji else { return }
        guard let color = selectedColor else { return }
        guard let category = selectedCategory else { return }
        viewModel.name = title
        viewModel.selectedEmoji = emoji
        viewModel.selectedColor = color
        viewModel.selectedCategory = category
        viewModel.selectedDays = selectedDays
        viewModel.saveChanges()
        dismiss(animated: true)
    }
}

extension EditHabitViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            let categoryVC = CategoryViewController(store: TrackerCategoryStore(context: context))
            categoryVC.onCategorySelected = { [weak self] category in
                self?.selectedCategory = category
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            if let sheet = categoryVC.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 16
            }
            present(categoryVC, animated: true)
        }
        if indexPath.row == 1 {
            let scheduleVC = ScheduleViewController()
            scheduleVC.selectedDays = selectedDays
            scheduleVC.onDone = { [weak self] days in
                self?.selectedDays = days
                self?.updateDaysCountLabel()
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            if let sheet = scheduleVC.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 16
            }
            present(scheduleVC, animated: true)
        }
    }
}
