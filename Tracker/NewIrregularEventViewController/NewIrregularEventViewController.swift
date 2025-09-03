import UIKit

final class NewIrregularEventViewController: UIViewController {

    // MARK: - UI
    private let modalHeader = ModalHeaderView(title: "Новое нерегулярное событие")
    private let nameTextField = AppTextField(placeholder: "Введите название трекера")
    private let tableContainer = ContainerTableView(
        backgroundColor: .systemGray6,
        cornerRadius: AppLayout.cornerRadius
    )
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
        tableView.contentInset = .zero
        tableView.layoutMargins = .zero
        tableView.backgroundColor = .clear

        setupLayout()
        setupActions()

        tableContainer.updateHeight(forRows: 2)
    }

    // MARK: - Layout
    private func setupLayout() {
        [modalHeader, nameTextField, tableContainer, bottomButtons].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            // Заголовок
            modalHeader.topAnchor.constraint(equalTo: view.topAnchor),
            modalHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            modalHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Текстовое поле
            nameTextField.topAnchor.constraint(equalTo: modalHeader.bottomAnchor, constant: AppLayout.padding),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.horizontalPadding),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.horizontalPadding),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),

            // Таблица (одна ячейка)
            tableContainer.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: AppLayout.padding),
            tableContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.horizontalPadding),
            tableContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.horizontalPadding),

            // Панель кнопок снизу
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
        // логика создания нерегулярного события
    }
}

// MARK: - UITableViewDataSource
extension NewIrregularEventViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContainerTableViewCell
        cell.textLabel?.text = "Категория"
        cell.accessoryType = .disclosureIndicator
        cell.isLastCell = true
        return cell
    }
}

// MARK: - UITableViewDelegate
extension NewIrregularEventViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.rowHeight
    }
}
