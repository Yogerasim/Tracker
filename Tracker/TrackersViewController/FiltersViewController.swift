import UIKit

final class FiltersViewController: UIViewController {
    
    // MARK: - UI
    private let header = ModalHeaderView(title: "Фильтры")
    private let tableContainer = ContainerTableView()
    
    // MARK: - Constraints
    private var tableHeightConstraint: NSLayoutConstraint?
    
    // MARK: - State
    private let filters = [
        "Все трекеры",
        "Трекеры на сегодня",
        "Завершенные",
        "Не завершенные"
    ]
    var selectedFilterIndex: Int? {
        didSet {
            guard let index = selectedFilterIndex else { return }
            UserDefaults.standard.set(index, forKey: "selectedFilterIndex")
        }
    }
    
    var onFilterSelected: ((Int) -> Void)?
    
    // MARK: - Constants
    private enum Constants {
        static let checkmarkImageName = "ic 24x24"
        static let rowHeight: CGFloat = 75
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        setupLayout()
        setupTableView()
        if let savedIndex = UserDefaults.standard.value(forKey: "selectedFilterIndex") as? Int {
            selectedFilterIndex = savedIndex
            onFilterSelected?(savedIndex)
        }
    }
    
    // MARK: - Layout
    private func setupLayout() {
        [header, tableContainer].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        tableHeightConstraint = tableContainer.heightAnchor.constraint(equalToConstant: CGFloat(filters.count) * Constants.rowHeight)
        tableHeightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 90),
            
            tableContainer.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 16),
            tableContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableContainer.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: - Setup
    private func setupTableView() {
        let tableView = tableContainer.tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ContainerTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = Constants.rowHeight
    }
    
    // MARK: - Helpers
    private func updateHeight(forRows count: Int) {
        tableHeightConstraint?.constant = CGFloat(count) * Constants.rowHeight
        view.layoutIfNeeded()
    }
    
    private func configureCheckmark(for cell: UITableViewCell, at indexPath: IndexPath) {
        if indexPath.row == selectedFilterIndex {
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

// MARK: - UITableViewDataSource & UITableViewDelegate
extension FiltersViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? ContainerTableViewCell else {
            return UITableViewCell()
        }
        
        if filters.indices.contains(indexPath.row) {
            cell.textLabel?.text = filters[indexPath.row]
            cell.isLastCell = indexPath.row == filters.count - 1
            configureCheckmark(for: cell, at: indexPath)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let previousIndex = selectedFilterIndex
        selectedFilterIndex = indexPath.row
        
        var indexPathsToReload: [IndexPath] = [indexPath]
        if let previous = previousIndex, previous != indexPath.row {
            indexPathsToReload.append(IndexPath(row: previous, section: 0))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.onFilterSelected?(indexPath.row)
            self.dismiss(animated: true)
        }
    }
}
