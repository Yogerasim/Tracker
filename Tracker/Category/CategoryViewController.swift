import UIKit

final class CategoryViewController: UIViewController {

    private let header = ModalHeaderView(title: "Категория")
    private let placeholderView = PlaceholderView()
    private let addButton = BlackButton(title: "Добавьте категорию")
    private let tableContainer = ContainerTableView()

    private let viewModel: CategoryViewModel
    private let categoryStore: TrackerCategoryStore

    // Отслеживаем выбранную категорию
    private var selectedCategoryIndex: Int?

    // MARK: - Init
    init(viewModel: CategoryViewModel, store: TrackerCategoryStore) {
        self.viewModel = viewModel
        self.categoryStore = store
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        setupLayout()
        setupTableView()
        bindViewModel()
    }

    // MARK: - Layout
    private func setupLayout() {
        [header, tableContainer, placeholderView, addButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 90),

            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 60),

            tableContainer.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 16),
            tableContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableContainer.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -16),

            placeholderView.topAnchor.constraint(equalTo: tableContainer.topAnchor),
            placeholderView.leadingAnchor.constraint(equalTo: tableContainer.leadingAnchor),
            placeholderView.trailingAnchor.constraint(equalTo: tableContainer.trailingAnchor),
            placeholderView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }

    private func setupTableView() {
        let tableView = tableContainer.tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ContainerTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = 75
    }

    private func bindViewModel() {
        placeholderView.configure(text: "Привычки и события можно\nобъединить по смыслу")
        placeholderView.isHidden = !viewModel.categories.isEmpty
        tableContainer.isHidden = viewModel.categories.isEmpty

        addButton.addTarget(self, action: #selector(addCategoryTapped), for: .touchUpInside)

        viewModel.onCategoriesChanged = { [weak self] categories in
            guard let self = self else { return }
            let hasCategories = !categories.isEmpty
            self.placeholderView.isHidden = hasCategories
            self.tableContainer.isHidden = !hasCategories
            self.tableContainer.updateHeight(forRows: categories.count)
            self.tableContainer.tableView.reloadData()
        }
    }

    @objc private func addCategoryTapped() {
        let newCategoryVM = NewCategoryViewModel(store: categoryStore)
        newCategoryVM.onCategoryCreated = { [weak self] category in
            self?.viewModel.add(category)
        }

        let newCategoryVC = NewCategoryViewController(viewModel: newCategoryVM)
        present(newCategoryVC, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension CategoryViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContainerTableViewCell
        cell.textLabel?.text = viewModel.categoryName(at: indexPath.row)
        cell.isLastCell = indexPath.row == viewModel.numberOfRows - 1

        // Показываем галочку только для выбранной категории
        if indexPath.row == selectedCategoryIndex {
            let checkmark = UIImageView(image: UIImage(named: "ic 24x24"))
            checkmark.contentMode = .scaleAspectFit
            // контейнер чуть выше separator
            let container = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: tableView.rowHeight - 1))
            checkmark.frame = CGRect(x: 0, y: 0, width: 24, height: tableView.rowHeight - 1)
            container.addSubview(checkmark)
            cell.accessoryView = container
        } else {
            cell.accessoryView = nil
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Сохраняем выбранный индекс и перезагружаем таблицу
        selectedCategoryIndex = indexPath.row
        tableView.reloadData()

        viewModel.selectCategory(at: indexPath.row)
    }
}
