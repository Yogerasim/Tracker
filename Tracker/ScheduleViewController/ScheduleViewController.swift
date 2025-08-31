import UIKit

final class ScheduleViewController: UIViewController {

    // MARK: - Properties
    var trackerName: String!  // Имя трекера из NewHabitVC
    var onTrackerCreated: ((Tracker) -> Void)?

    private var selectedDays: [WeekDay] = []
    private let daysOfWeek: [(title: String, day: WeekDay)] = [
        ("Понедельник", .monday),
        ("Вторник", .tuesday),
        ("Среда", .wednesday),
        ("Четверг", .thursday),
        ("Пятница", .friday),
        ("Суббота", .saturday),
        ("Воскресенье", .sunday)
    ]

    // MARK: - UI
    private let modalHeader = ModalHeaderView(title: "Расписание")
    private let tableContainer = ContainerTableView()
    private let bottomButtons = ButonsPanelView()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background

        let tableView = tableContainer.tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ContainerTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = 75

        setupLayout()
        setupActions()
        tableContainer.updateHeight(forRows: daysOfWeek.count)

        print("📅 ScheduleViewController загружен для трекера '\(trackerName ?? "Без имени")'")
    }

    // MARK: - Layout
    private func setupLayout() {
        [modalHeader, tableContainer, bottomButtons].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            modalHeader.topAnchor.constraint(equalTo: view.topAnchor),
            modalHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            modalHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableContainer.topAnchor.constraint(equalTo: modalHeader.bottomAnchor, constant: AppLayout.padding),
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
        print("✖️ ScheduleViewController: отмена — возвращаемся в NewHabitViewController")
        dismiss(animated: true)
    }

    @objc private func createTapped() {
        print("✅ ScheduleViewController: Создать трекер '\(trackerName!)' с выбранными днями: \(selectedDays.map { $0.rawValue })")

        let tracker = Tracker(
            id: UUID(),
            name: trackerName,
            color: "#FD4C49",
            emoji: "📚",
            schedule: selectedDays
        )

        onTrackerCreated?(tracker)
    }
}

// MARK: - UITableViewDataSource
extension ScheduleViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { daysOfWeek.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContainerTableViewCell
        let item = daysOfWeek[indexPath.row]

        cell.textLabel?.text = item.title
        cell.isLastCell = (indexPath.row == daysOfWeek.count - 1)

        let toggle = UISwitch()
        toggle.tag = indexPath.row
        toggle.isOn = selectedDays.contains(item.day)
        toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)
        cell.accessoryView = toggle

        return cell
    }
}

// MARK: - UITableViewDelegate
extension ScheduleViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { tableView.rowHeight }
}

// MARK: - UISwitch Handler
extension ScheduleViewController {
    @objc private func toggleChanged(_ sender: UISwitch) {
        let day = daysOfWeek[sender.tag].day
        if sender.isOn {
            if !selectedDays.contains(day) { selectedDays.append(day) }
            print("➕ Schedule: добавлен день \(day)")
        } else {
            selectedDays.removeAll { $0 == day }
            print("➖ Schedule: удалён день \(day)")
        }
    }
}
