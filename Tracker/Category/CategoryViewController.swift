import UIKit
import CoreData

final class CategoryViewController: UIViewController {

    // MARK: - UI
    private let header = ModalHeaderView(
        title: NSLocalizedString("category_title", comment: "Заголовок экрана выбора категории")
    )
    private let placeholderView = PlaceholderView()
    private let addButton = BlackButton(
        title: NSLocalizedString("add_category_button", comment: "Кнопка добавления новой категории")
    )
    private let tableContainer = ContainerTableView()
    
    // MARK: - Dependencies
    private let categoryStore: TrackerCategoryStore

    // MARK: - State
    private var selectedCategoryIndex: Int?
    var onCategorySelected: ((TrackerCategoryCoreData) -> Void)?

    // MARK: - Constants
    private enum Constants {
        static let checkmarkImageName = "ic 24x24" // имя картинки — не локализуем
        static let rowHeight: CGFloat = 75
    }

    // MARK: - Init
    init(store: TrackerCategoryStore) {
        self.categoryStore = store
        super.init(nibName: nil, bundle: nil)
        self.categoryStore.delegate = self
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        setupLayout()
        setupTableView()
        setupActions()
        updateUI()
    }

    // MARK: - UI Setup
    private func setupLayout() {
        [header, tableContainer, placeholderView, addButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            // Header
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 90),
            
            // Add Button
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 60),
            
            // Table Container (без bottomAnchor!)
            tableContainer.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 16),
            tableContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Placeholder View
            placeholderView.topAnchor.constraint(equalTo: tableContainer.topAnchor),
            placeholderView.leadingAnchor.constraint(equalTo: tableContainer.leadingAnchor),
            placeholderView.trailingAnchor.constraint(equalTo: tableContainer.trailingAnchor),
            placeholderView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        // Динамическая высота таблицы в зависимости от количества категорий
        let categories = categoryStore.fetchCategories()
        tableContainer.updateHeight(forRows: categories.count)
    }

    private func setupTableView() {
        let tableView = tableContainer.tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ContainerTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = Constants.rowHeight
    }

    private func setupActions() {
        addButton.addTarget(self, action: #selector(addCategoryTapped), for: .touchUpInside)
    }

    private func updateUI() {
        let categories = categoryStore.fetchCategories()
        let hasCategories = !categories.isEmpty
        placeholderView.configure(
            imageName: "Star",
            text: NSLocalizedString(
                "category_placeholder",
                comment: "Текст плейсхолдера для пустого списка категорий"
            )
        )
        placeholderView.isHidden = hasCategories
        tableContainer.isHidden = !hasCategories
        tableContainer.updateHeight(forRows: categories.count)
        tableContainer.tableView.reloadData()
    }
    
    

    @objc private func addCategoryTapped() {
        let newCategoryVM = NewCategoryViewModel(store: categoryStore)
        newCategoryVM.onCategoryCreated = { [weak self] category in
            self?.categoryStore.add(category)
            self?.updateUI()
        }

        let newCategoryVC = NewCategoryViewController(viewModel: newCategoryVM)
        present(newCategoryVC, animated: true)
    }

    // MARK: - Helpers
    private func configureCheckmark(for cell: UITableViewCell, at indexPath: IndexPath) {
        if indexPath.row == selectedCategoryIndex {
            let checkmark = UIImageView(image: UIImage(named: Constants.checkmarkImageName))
            checkmark.contentMode = .scaleAspectFit

            let container = UIView(
                frame: CGRect(x: 0, y: 0, width: 24, height: Int(Constants.rowHeight) - 1)
            )
            checkmark.frame = container.bounds
            container.addSubview(checkmark)

            cell.accessoryView = container
        } else {
            cell.accessoryView = nil
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension CategoryViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        categoryStore.fetchCategories().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContainerTableViewCell
        let category = categoryStore.fetchCategories()[indexPath.row]
        cell.textLabel?.text = category.title
        cell.isLastCell = indexPath.row == categoryStore.fetchCategories().count - 1

        configureCheckmark(for: cell, at: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let previousIndex = selectedCategoryIndex
        selectedCategoryIndex = indexPath.row

        var indexPathsToReload: [IndexPath] = [indexPath]
        if let previous = previousIndex, previous != indexPath.row {
            indexPathsToReload.append(IndexPath(row: previous, section: 0))
        }
        tableView.reloadRows(at: indexPathsToReload, with: .none)

        let selectedCategory = categoryStore.fetchCategories()[indexPath.row]
        print("Выбрана категория: \(selectedCategory.title ?? "")") // можно оставить как debug
        onCategorySelected?(selectedCategory)
    }
}

// MARK: - TrackerCategoryStoreDelegate
extension CategoryViewController: TrackerCategoryStoreDelegate {
    func didUpdateCategories() {
        updateUI()
    }
}

