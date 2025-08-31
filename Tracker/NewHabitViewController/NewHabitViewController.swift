import UIKit

final class NewHabitViewController: UIViewController {

    // MARK: - UI
    private let modalHeader = ModalHeaderView(title: "Новая привычка")
    private let nameTextField = AppTextField(placeholder: "Введите название трекера")
    private let tableContainer = ContainerTableView(backgroundColor: .systemGray6, cornerRadius: AppLayout.cornerRadius)
    private let bottomButtons = ButonsPanelView()

    // MARK: - Callbacks
    /// TrackersViewController подпишется на это, чтобы получить итоговый Tracker
    var onHabitCreated: ((Tracker) -> Void)?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        setupTable()
        setupLayout()
        setupActions()
        print("➕ NewHabitViewController загружен")
    }

    // MARK: - Setup Table
    private func setupTable() {
        let tableView = tableContainer.tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ContainerTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .none
        tableView.contentInset = .zero
        tableView.layoutMargins = .zero
        tableView.backgroundColor = .clear
        tableContainer.updateHeight(forRows: tableView.numberOfRows(inSection: 0))
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

    /// Переход в ScheduleViewController
    @objc private func createTapped() {
        guard let title = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty else {
            print("⚠️ NewHabitViewController: имя трекера не задано")
            return
        }

        print("✏️ NewHabitViewController: введено имя '\(title)' — открываем ScheduleViewController")

        let scheduleVC = ScheduleViewController()
        scheduleVC.trackerName = title
        scheduleVC.onTrackerCreated = { [weak self] tracker in
            guard let self = self else { return }
            print("🟢 Schedule -> NewHabit: создан Tracker '\(tracker.name)' с расписанием: \(tracker.schedule.map { $0.rawValue })")

            // Проброс наружу в TrackersViewController
            self.onHabitCreated?(tracker)

            // Закрываем оба экрана
            self.dismiss(animated: true)
        }

        present(scheduleVC, animated: true)
        print("📅 NewHabitViewController: открыт ScheduleViewController")
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
        print("📌 NewHabitViewController: выбран ряд \(indexPath.row) — открытие Schedule только через кнопку 'Создать'")
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { tableView.rowHeight }
}
