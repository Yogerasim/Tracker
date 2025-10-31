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
    required init?(coder: NSCoder) { return nil }
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
        let count = viewModel.completedDaysCount
        daysCountLabel.text = localizedDaysText(for: count)
    }
    func localizedDaysText(for count: Int) -> String {
        let locale: String
        if #available(iOS 16.0, *) {
            locale = Locale.current.language.languageCode?.identifier ?? "en"
        } else {
            locale = Locale.current.languageCode ?? "en"
        }
        if locale == "ru" {
            let absVal = abs(count) % 100
            let last = absVal % 10

            let key: String
            if absVal > 10 && absVal < 20 { key = "edit_habit.days_count.many" }
            else if last == 1 { key = "edit_habit.days_count.one" }
            else if last >= 2 && last <= 4 { key = "edit_habit.days_count.few" }
            else { key = "edit_habit.days_count.many" }
            return String(format: NSLocalizedString(key, comment: ""), count)
        } else {
            let key = count == 1
                ? "edit_habit.days_count.one"
                : "edit_habit.days_count.other"
            return String(format: NSLocalizedString(key, comment: ""), count)
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
