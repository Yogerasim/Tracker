import UIKit
import CoreData

class BaseTrackerCreationViewController: UIViewController {
    
    // MARK: - UI
    let scrollView = UIScrollView()
    let contentStack = UIStackView()
    let modalHeader: ModalHeaderView
    let nameTextField = AppTextField(
        placeholder: NSLocalizedString("new_habit.enter_name", comment: ""),
        maxCharacters: 38
    )
    let tableContainer = ContainerTableView()
    let emojiCollectionVC = SelectableCollectionViewController(
        items: CollectionData.emojis,
        headerTitle: NSLocalizedString("new_habit.emoji", comment: "")
    )
    let colorCollectionVC = SelectableCollectionViewController(
        items: CollectionData.colors,
        headerTitle: NSLocalizedString("new_habit.color", comment: "")
    )
    let bottomButtons = ButonnsPanelView()
    
    // MARK: - Core Data
    let context = CoreDataStack.shared.context
    
    // MARK: - State
    var selectedDays: [WeekDay] = []
    var selectedEmoji: String?
    var selectedColor: UIColor?
    var selectedCategory: TrackerCategoryCoreData?
    
    // MARK: - Init
    init(title: String) {
        self.modalHeader = ModalHeaderView(title: title)
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        setupTable()
        setupLayout()
        setupActions()
        setupSelectionCallbacks()
        setupTextField()
    }
    
    // MARK: - UI Setup
    private func setupTextField() {
        nameTextField.onTextChanged = { [weak self] text in
            let hasText = !text.trimmingCharacters(in: .whitespaces).isEmpty
            self?.bottomButtons.setCreateButton(enabled: hasText)
        }
    }
    
    private func setupSelectionCallbacks() {
        emojiCollectionVC.onItemSelected = { [weak self] item in
            if case .emoji(let emoji) = item { self?.selectedEmoji = emoji }
        }
        colorCollectionVC.onItemSelected = { [weak self] item in
            if case .color(let color) = item { self?.selectedColor = color }
        }
    }
    
    private func setupTable() {
        let tableView = tableContainer.tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ContainerTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = 75
    }
    
    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = AppLayout.padding
        
        modalHeader.translatesAutoresizingMaskIntoConstraints = false
        bottomButtons.translatesAutoresizingMaskIntoConstraints = false
        modalHeader.backgroundColor = AppColors.background
        bottomButtons.backgroundColor = AppColors.background
        
        view.addSubview(modalHeader)
        view.addSubview(scrollView)
        view.addSubview(bottomButtons)
        scrollView.addSubview(contentStack)
        
        [nameTextField, tableContainer, emojiCollectionVC.view, colorCollectionVC.view].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentStack.addArrangedSubview($0)
        }
        
        addChild(emojiCollectionVC)
        emojiCollectionVC.didMove(toParent: self)
        addChild(colorCollectionVC)
        colorCollectionVC.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            modalHeader.topAnchor.constraint(equalTo: view.topAnchor),
            modalHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            modalHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            modalHeader.heightAnchor.constraint(equalToConstant: 90),
            
            bottomButtons.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomButtons.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomButtons.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            scrollView.topAnchor.constraint(equalTo: modalHeader.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomButtons.topAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: AppLayout.padding),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: UIConstants.horizontalPadding),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -UIConstants.horizontalPadding),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -AppLayout.padding),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -2 * UIConstants.horizontalPadding),
            
            nameTextField.heightAnchor.constraint(equalToConstant: 75),
            tableContainer.heightAnchor.constraint(equalToConstant: 150),
            emojiCollectionVC.view.heightAnchor.constraint(equalToConstant: 300),
            colorCollectionVC.view.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func setupActions() {
        bottomButtons.cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
    }
    
    @objc func cancelTapped() {
        dismiss(animated: true)
    }
    
    func numberOfRowsInTable() -> Int { 2 }
    
    func tableViewCell(for tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContainerTableViewCell
        if indexPath.row == 0 {
            cell.configure(title: NSLocalizedString("new_habit.category", comment: ""), detail: selectedCategory?.title ?? "")
        } else {
            let detailText = selectedDays.isEmpty ? nil : selectedDays.descriptionText
            cell.configure(title: NSLocalizedString("new_habit.schedule", comment: ""), detail: detailText)
        }
        cell.isLastCell = indexPath.row == numberOfRowsInTable() - 1
        return cell
    }
    
    func didSelectRow(at indexPath: IndexPath, tableView: UITableView) { }
}

// MARK: - UITableView
extension BaseTrackerCreationViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { numberOfRowsInTable() }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableViewCell(for: tableView, indexPath: indexPath)
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectRow(at: indexPath, tableView: tableView)
    }
}
