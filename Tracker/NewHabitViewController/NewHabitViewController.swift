import UIKit

final class NewHabitViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    
    private let modalHeader = ModalHeaderView(title: NSLocalizedString("new_habit.title", comment: "Новая привычка"))
    private let nameTextField = AppTextField(placeholder: NSLocalizedString("new_habit.enter_name", comment: "Введите название трекера"))
    private let tableContainer = ContainerTableView()
    private let emojiCollectionVC = SelectableCollectionViewController(
        items: CollectionData.emojis,
        headerTitle: NSLocalizedString("new_habit.emoji", comment: "Emoji")
    )
    private let colorCollectionVC = SelectableCollectionViewController(
        items: CollectionData.colors,
        headerTitle: NSLocalizedString("new_habit.color", comment: "Цвет")
    )
    private let bottomButtons = ButonsPanelView()
    
    // MARK: - Callback
    var onHabitCreated: ((Tracker) -> Void)?
    
    // MARK: - State
    private var selectedDays: [WeekDay] = []
    private var selectedEmoji: String?
    private var selectedColor: UIColor?
    private var selectedCategory: TrackerCategoryCoreData?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        
        setupTable()
        setupLayout()
        setupActions()
        
        nameTextField.delegate = self
        print("➕ NewHabitViewController загружен")
        
        emojiCollectionVC.onItemSelected = { [weak self] item in
            if case .emoji(let emoji) = item {
                self?.selectedEmoji = emoji
            }
        }
        
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
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = 75
        tableContainer.updateHeight(forRows: 2)
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
        
        contentStack.setCustomSpacing(0, after: emojiCollectionVC.view)
        
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
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -2*UIConstants.horizontalPadding),
            
            nameTextField.heightAnchor.constraint(equalToConstant: 75),
            tableContainer.heightAnchor.constraint(equalToConstant: 150),
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
        print("✖️ \(NSLocalizedString("new_habit.cancel_log", comment: "NewHabitViewController: отмена"))")
        dismiss(animated: true)
    }
    
    @objc private func createTapped() {
        guard let title = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else { return }
        guard let emoji = selectedEmoji else {
            print("⚠️ \(NSLocalizedString("new_habit.choose_emoji", comment: "Выберите эмодзи"))")
            return
        }
        guard let color = selectedColor else {
            print("⚠️ \(NSLocalizedString("new_habit.choose_color", comment: "Выберите цвет"))")
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
        
        onHabitCreated?(tracker)
        dismiss(animated: true)
    }
    
    // MARK: - UITextField
    func textFieldDidChangeSelection(_ textField: UITextField) {
        let hasText = !(textField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        bottomButtons.setCreateButton(enabled: hasText)
    }
}

// MARK: - UITableView
extension NewHabitViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 2 }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContainerTableViewCell
        if indexPath.row == 0 {
            cell.textLabel?.text = selectedCategory?.title ?? NSLocalizedString("new_habit.category", comment: "Категория")
        } else {
            cell.textLabel?.text = NSLocalizedString("new_habit.schedule", comment: "Расписание")
        }
        cell.accessoryType = .disclosureIndicator
        cell.isLastCell = indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
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

        if indexPath.row == 1 {
            let scheduleVC = ScheduleViewController()
            scheduleVC.selectedDays = selectedDays
            scheduleVC.onDone = { [weak self] days in
                self?.selectedDays = days
            }
            present(scheduleVC, animated: true)
        }
    }
}

// MARK: - UIColor extension
extension UIColor {
    func toHexString() -> String {
        guard let components = cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX",
                      lroundf(r * 255),
                      lroundf(g * 255),
                      lroundf(b * 255))
    }
}
