import UIKit
import CoreData

final class CategoryViewController: UIViewController {
    
    
    private let header = ModalHeaderView(
        title: NSLocalizedString("category_title", comment: "Заголовок экрана выбора категории")
    )
    private let placeholderView = PlaceholderView()
    private let addButton = BlackButton(
        title: NSLocalizedString("add_category_button", comment: "Кнопка добавления новой категории")
    )
    private let tableContainer = ContainerTableView()
    
    
    private let categoryStore: TrackerCategoryStore
    
    
    private var selectedCategoryIndex: Int?
    private var contextMenuController: BaseContextMenuController<UITableViewCell>?
    var onCategorySelected: ((TrackerCategoryCoreData) -> Void)?
    
    
    private enum Constants {
        static let checkmarkImageName = "ic 24x24"
        static let rowHeight: CGFloat = 75
    }
    
    
    init(store: TrackerCategoryStore) {
        self.categoryStore = store
        super.init(nibName: nil, bundle: nil)
        self.categoryStore.delegate = self
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        setupLayout()
        setupTableView()
        setupContextMenuController()
        setupActions()
        updateUI()
    }
    
    
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
            
            placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

        ])
        
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
    
    private func setupContextMenuController() {
        contextMenuController = BaseContextMenuController(
            owner: self,
            container: tableContainer.tableView,
            indexPathProvider: { [weak self] cell in
                self?.tableContainer.tableView.indexPath(for: cell)
            },
            actionsProvider: { [weak self] indexPath in
                guard let self else { return [] }
                let categories = self.categoryStore.fetchCategories()
                guard categories.indices.contains(indexPath.row) else { return [] }
                let category = categories[indexPath.row]
                
                let edit = UIAction(
                    title: NSLocalizedString("category.action.edit", comment: "Edit"),
                    image: UIImage(systemName: "pencil")
                ) { _ in
                    self.editCategory(category)
                }
                
                let delete = UIAction(
                    title: NSLocalizedString("category.action.delete", comment: "Delete"),
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive
                ) { _ in
                    self.deleteCategory(category)
                }
                
                return [edit, delete]
            }
        )
    }
    
    
    private func editCategory(_ category: TrackerCategoryCoreData) {
        guard let context = category.managedObjectContext else { return }
        
        let editVM = EditCategoryViewModel(category: category, context: context)
        let editVC = EditCategoryViewController(viewModel: editVM)
        present(editVC, animated: true)
    }
    
    private func deleteCategory(_ category: TrackerCategoryCoreData) {
        guard let title = category.title else { return }
        
        let alert = UIAlertController(
            title: NSLocalizedString("category.action.delete_alert_title", comment: "Delete category?"),
            message: String(format: NSLocalizedString("category.action.delete_alert_message", comment: "Are you sure you want to delete the category?"), title),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("category.action.delete", comment: "Delete"), style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            if let context = category.managedObjectContext {
                context.delete(category)
                do {
                    try context.save()
                    self.updateUI()
                } catch {
                }
            }
        })
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("category.action.cancel", comment: "Cancel"), style: .cancel))
        present(alert, animated: true)
    }
    
    
    private func configureCheckmark(for cell: UITableViewCell, at indexPath: IndexPath) {
        if indexPath.row == selectedCategoryIndex {
            let checkmark = UIImageView(image: UIImage(named: Constants.checkmarkImageName))
            checkmark.contentMode = .scaleAspectFit
            
            let container = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: Int(Constants.rowHeight) - 1))
            checkmark.frame = container.bounds
            container.addSubview(checkmark)
            cell.accessoryView = container
        } else {
            cell.accessoryView = nil
        }
    }
}


extension CategoryViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        categoryStore.fetchCategories().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? ContainerTableViewCell else {
            return UITableViewCell()
        }
        
        let categories = categoryStore.fetchCategories()
        if categories.indices.contains(indexPath.row) {
            let category = categories[indexPath.row]
            cell.textLabel?.text = category.title ?? ""
            cell.isLastCell = indexPath.row == categories.count - 1
            configureCheckmark(for: cell, at: indexPath)
            contextMenuController?.attach(to: cell)
        }
        
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
        onCategorySelected?(selectedCategory)
    }
}


extension CategoryViewController: TrackerCategoryStoreDelegate {
    func didUpdateCategories() {
        updateUI()
    }
}
