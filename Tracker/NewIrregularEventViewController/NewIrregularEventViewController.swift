import UIKit

final class NewIrregularEventViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var selectedCategory: TrackerCategoryCoreData?
    
    private let modalHeader = ModalHeaderView(title: "Новое нерегулярное событие")
    private let nameTextField = AppTextField(placeholder: "Введите название трекера")
    private let tableContainer = ContainerTableView()
    private let emojiCollectionVC = SelectableCollectionViewController(items: CollectionData.emojis, headerTitle: "Emoji")
    private let colorCollectionVC = SelectableCollectionViewController(items: CollectionData.colors, headerTitle: "Цвет")
    private let bottomButtons = ButonsPanelView()
    
    // MARK: - Callback
    var onEventCreated: ((Tracker) -> Void)?
    
    // MARK: - State
    private var selectedEmoji: String?
    private var selectedColor: UIColor?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        
        setupTable()
        setupLayout()
        setupActions()
        nameTextField.delegate = self
        
        print("➕ NewIrregularEventViewController загружен")
        
        // Обработка выбора эмоджи
        emojiCollectionVC.onItemSelected = { [weak self] item in
            if case .emoji(let emoji) = item {
                self?.selectedEmoji = emoji
            }
        }
        
        // Обработка выбора цвета
        colorCollectionVC.onItemSelected = { [weak self] item in
            if case .color(let color) = item {
                self?.selectedColor = color
            }
        }
    }
    
    // MARK: - Table setup
    private func setupTable() {
        let tableView = tableContainer.tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ContainerTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.isScrollEnabled = false
        tableView.rowHeight = 75
        tableContainer.updateHeight(forRows: 1)
    }
    
    // MARK: - Layout
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
            // Header
            modalHeader.topAnchor.constraint(equalTo: view.topAnchor),
            modalHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            modalHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            modalHeader.heightAnchor.constraint(equalToConstant: 90),
            
            // Bottom buttons
            bottomButtons.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomButtons.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomButtons.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: modalHeader.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomButtons.topAnchor),
            
            // StackView
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: AppLayout.padding),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: UIConstants.horizontalPadding),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -UIConstants.horizontalPadding),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -AppLayout.padding),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -2*UIConstants.horizontalPadding),
            
            // Fixed heights
            nameTextField.heightAnchor.constraint(equalToConstant: 75),
            tableContainer.heightAnchor.constraint(equalToConstant: 75),
            emojiCollectionVC.view.heightAnchor.constraint(equalToConstant: 300),
            colorCollectionVC.view.heightAnchor.constraint(equalToConstant: 200)
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
        guard let title = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else { return }
        guard let emoji = selectedEmoji else {
            print("⚠️ Выберите эмодзи")
            return
        }
        guard let color = selectedColor else {
            print("⚠️ Выберите цвет")
            return
        }
        
        let tracker = Tracker(
            id: UUID(),
            name: title,
            color: color.toHexString(),
            emoji: emoji,
            schedule: [],
            trackerCategory: selectedCategory
            )

        
        onEventCreated?(tracker)
        dismiss(animated: true)
    }
    
    // MARK: - UITextField
    func textFieldDidChangeSelection(_ textField: UITextField) {
        let hasText = !(textField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        bottomButtons.setCreateButton(enabled: hasText)
    }
}

// MARK: - UITableView
extension NewIrregularEventViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContainerTableViewCell
        cell.textLabel?.text = selectedCategory?.title ?? "Категория"
        cell.accessoryType = .disclosureIndicator
        cell.isLastCell = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Переход к CategoryViewController
        let coreDataStack = CoreDataStack.shared
        let categoryStore = TrackerCategoryStore(context: coreDataStack.context)
        let categoryVM = CategoryViewModel(store: categoryStore)
        let categoryVC = CategoryViewController(store: categoryStore)
        
        categoryVM.onCategorySelected = { [weak self] category in
            self?.selectedCategory = category
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        
        present(categoryVC, animated: true)
    }
}
