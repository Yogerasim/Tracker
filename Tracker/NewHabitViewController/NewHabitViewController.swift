import UIKit

final class NewHabitViewController: UIViewController, UITextFieldDelegate {

    // MARK: - UI
    private let modalHeader = ModalHeaderView(title: "Новая привычка")
    private let nameTextField = AppTextField(placeholder: "Введите название трекера")
    private let tableContainer = ContainerTableView()
    private let bottomButtons = ButonsPanelView()

    // MARK: - Callback
    var onHabitCreated: ((Tracker) -> Void)?

    // MARK: - State
    private var selectedDays: [WeekDay] = []
    
    private var scheduleVC: ScheduleViewController?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        setupTable()
        setupLayout()
        setupActions()
        nameTextField.delegate = self
        print("➕ NewHabitViewController загружен")
    }

    // MARK: - Table setup
    private func setupTable() {
        let tableView = tableContainer.tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ContainerTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = 75
        tableContainer.updateHeight(forRows: 2)
    }

    // MARK: - Layout
    private func setupLayout() {
        [modalHeader, nameTextField, tableContainer, bottomButtons].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            modalHeader.topAnchor.constraint(equalTo: view.topAnchor),
            modalHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            modalHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            nameTextField.topAnchor.constraint(equalTo: modalHeader.bottomAnchor, constant: AppLayout.padding),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.horizontalPadding),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.horizontalPadding),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),

            tableContainer.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: AppLayout.padding),
            tableContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.horizontalPadding),
            tableContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.horizontalPadding),

            bottomButtons.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomButtons.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomButtons.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Actions
    private func setupActions() {
        bottomButtons.cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        bottomButtons.createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
    }

    @objc private func cancelTapped() {
        print("✖️ NewHabitViewController: отмена")
        dismiss(animated: true)
    }

    @objc private func createTapped() {
        guard let title = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else { return }

        print("🔹 selectedDays при создании трекера: \(selectedDays)")

        let tracker = Tracker(
            id: UUID(),
            name: title,
            color: "#FD4C49",
            emoji: "📚",
            schedule: selectedDays
        )

        onHabitCreated?(tracker)
        dismiss(animated: true)
    }

    // MARK: - UITextField
    func textFieldDidChangeSelection(_ textField: UITextField) {
        let hasText = !(textField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        bottomButtons.setCreateButton(enabled: hasText)
    }
}

// MARK: - UITableView
extension NewHabitViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 2 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContainerTableViewCell
        cell.textLabel?.text = indexPath.row == 0 ? "Категория" : "Расписание"
        cell.accessoryType = .disclosureIndicator
        cell.isLastCell = indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 1 {
            let scheduleVC = ScheduleViewController()
            scheduleVC.selectedDays = selectedDays
            scheduleVC.onDone = { [weak self] days in
                self?.selectedDays = days
            }
            present(scheduleVC, animated: true)
        }
    }
}
