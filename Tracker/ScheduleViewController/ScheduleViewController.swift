import UIKit

final class ScheduleViewController: UIViewController {

    // MARK: - UI
    private let modalHeader = ModalHeaderView(title: "Расписание")
    private let tableContainer = ContainerTableView()
    private let bottomButtons = ButonsPanelView()

    // Дни недели
    private let daysOfWeek = ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"]

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
        tableView.rowHeight = 75 // фиксированная высота строки

        setupLayout()
        setupActions()

        // обновляем высоту контейнера в зависимости от количества строк
        tableContainer.updateHeight(forRows: daysOfWeek.count)
    }

    // MARK: - Layout
    private func setupLayout() {
        [modalHeader, tableContainer, bottomButtons].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            // Заголовок
            modalHeader.topAnchor.constraint(equalTo: view.topAnchor),
            modalHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            modalHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Таблица
            tableContainer.topAnchor.constraint(equalTo: modalHeader.bottomAnchor, constant: AppLayout.padding),
            tableContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.horizontalPadding),
            tableContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.horizontalPadding),

            // Нижние кнопки
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
        dismiss(animated: true)
    }

    @objc private func createTapped() {
        // Логика сохранения расписания
    }
}

// MARK: - UITableViewDataSource
extension ScheduleViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return daysOfWeek.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContainerTableViewCell

        // Текст — день недели
        cell.textLabel?.text = daysOfWeek[indexPath.row]

        // Последняя ячейка — скрываем разделитель
        cell.isLastCell = indexPath.row == daysOfWeek.count - 1

        // Убираем стрелку
        cell.accessoryType = .none

        // Добавляем UISwitch справа (один раз на ячейку)
        if cell.contentView.viewWithTag(100) == nil {
            let toggle = UISwitch()
            toggle.tag = 100
            toggle.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(toggle)
            NSLayoutConstraint.activate([
                toggle.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                toggle.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
            ])
        }

        return cell
    }
}

// MARK: - UITableViewDelegate
extension ScheduleViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.rowHeight // всегда 75
    }
}
