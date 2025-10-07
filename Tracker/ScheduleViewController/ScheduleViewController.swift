import UIKit

final class ScheduleViewController: UIViewController {

    // MARK: - Properties
    var selectedDays: [WeekDay] = []
    var onDone: (([WeekDay]) -> Void)?

    private let daysOfWeek: [(titleKey: String, day: WeekDay)] = [
        ("schedule.monday", .monday),
        ("schedule.tuesday", .tuesday),
        ("schedule.wednesday", .wednesday),
        ("schedule.thursday", .thursday),
        ("schedule.friday", .friday),
        ("schedule.saturday", .saturday),
        ("schedule.sunday", .sunday)
    ]

    // MARK: - UI
    private let modalHeader = ModalHeaderView(title: NSLocalizedString("schedule.title", comment: "Заголовок расписания"))
    private let tableContainer = ContainerTableView()
    private let doneButton = DoneButton()

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
        updateDoneButtonState()
        print("📅 ScheduleViewController загружен")
    }

    // MARK: - Layout
    private func setupLayout() {
        [modalHeader, tableContainer, doneButton].forEach {
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

            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    // MARK: - Actions
    private func setupActions() {
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
    }

    @objc private func doneTapped() {
        print("✅ Done tapped, sending back selectedDays: \(selectedDays.map { $0.shortName })")
        onDone?(selectedDays)
        dismiss(animated: true)
    }

    private func updateDoneButtonState() {
        let enabled = true
        doneButton.isEnabled = enabled
        doneButton.backgroundColor = enabled ? AppColors.backgroundBlackButton : .systemGray3
        doneButton.setTitleColor(AppColors.textPrimary, for: .normal)
        doneButton.setTitle(NSLocalizedString("schedule.done_button", comment: "Кнопка завершения выбора дней"), for: .normal)
    }
}

// MARK: - UITableView
extension ScheduleViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { daysOfWeek.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContainerTableViewCell
        let item = daysOfWeek[indexPath.row]
        cell.textLabel?.text = NSLocalizedString(item.titleKey, comment: "")
        cell.isLastCell = indexPath.row == daysOfWeek.count - 1

        let toggle = UISwitch()
        toggle.tag = indexPath.row
        toggle.isOn = selectedDays.contains(item.day)
        toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)
        cell.accessoryView = toggle
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { tableView.rowHeight }
}

// MARK: - UISwitch Handler
extension ScheduleViewController {
    @objc private func toggleChanged(_ sender: UISwitch) {
        let day = daysOfWeek[sender.tag].day
        if sender.isOn {
            if !selectedDays.contains(day) {
                selectedDays.append(day)
                print("🔵 Added day: \(day.shortName), current selectedDays: \(selectedDays.map { $0.shortName })")
            }
        } else {
            selectedDays.removeAll { $0 == day }
            print("🔴 Removed day: \(day.shortName), current selectedDays: \(selectedDays.map { $0.shortName })")
        }

        updateDoneButtonState()
    }
}

extension WeekDay {
    var shortName: String {
        switch self {
        case .monday: return "Пн"
        case .tuesday: return "Вт"
        case .wednesday: return "Ср"
        case .thursday: return "Чт"
        case .friday: return "Пт"
        case .saturday: return "Сб"
        case .sunday: return "Вс"
        }
    }
    
}

extension Array where Element == WeekDay {
    var descriptionText: String {
        if self.count == WeekDay.allCases.count {
            return "Каждый день"
        } else if self.isEmpty {
            return NSLocalizedString("new_habit.schedule_not_selected", comment: "Не выбрано")
        } else {
            return self.map { $0.shortName }.joined(separator: ", ")
        }
    }
}
