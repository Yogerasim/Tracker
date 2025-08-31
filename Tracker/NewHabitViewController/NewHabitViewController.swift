import UIKit

final class NewHabitViewController: UIViewController {

    // MARK: - UI
    private let modalHeader = ModalHeaderView(title: "Новая привычка")
    private let nameTextField = AppTextField(placeholder: "Введите название трекера")
    private let tableContainer = ContainerTableView(backgroundColor: .systemGray6, cornerRadius: AppLayout.cornerRadius)
    private let bottomButtons = ButonsPanelView()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background

        let tableView = tableContainer.tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .none
        tableView.contentInset = .zero
        tableView.layoutMargins = .zero
        tableView.backgroundColor = .clear

        setupLayout()
        setupActions()
        
        tableContainer.updateHeight(forRows: tableView.numberOfRows(inSection: 0))
    }
    
    var onHabitCreated: ((Tracker) -> Void)?
    
    

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
        dismiss(animated: true)
    }

    @objc private func createTapped() {
        guard let title = nameTextField.text, !title.isEmpty else {
            // Можно показать alert или просто return
            return
        }

        // Создаём трекер
        let tracker = Tracker(
            id: UUID(),
            name: title,       
            color: "#FD4C49",
            emoji: "📚",
            schedule: []
        )

        // Вызываем замыкание для передачи трекера в TrackersViewController
        onHabitCreated?(tracker)

        // Закрываем текущий контроллер
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension NewHabitViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.register(ContainerTableViewCell.self, forCellReuseIdentifier: "cell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContainerTableViewCell

        // Динамический контент
        cell.textLabel?.text = indexPath.row == 0 ? "Категория" : "Расписание"
        cell.accessoryType = .disclosureIndicator

        // Последняя ячейка – скрываем разделитель
        cell.isLastCell = indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1

        return cell
    }
}

// MARK: - UITableViewDelegate
extension NewHabitViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.rowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.row {
        case 1:
            
            let scheduleVC = ScheduleViewController()
            presentFullScreenSheet(scheduleVC)

        default:
            break
        }
    }
}
