import UIKit
import CoreData

final class EditHabitViewController: UIViewController {

    // MARK: - Dependencies
    private let viewModel: EditHabitViewModel

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let modalHeader = ModalHeaderView(title: NSLocalizedString("edit_habit.title", comment: "Редактировать привычку"))
    
    // 🔹 Новый элемент — количество дней
    private let daysCountLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.bold(32)
        label.textColor = AppColors.backgroundBlackButton
        label.textAlignment = .center
        return label
    }()
    
    private let nameTextField = AppTextField(
        placeholder: NSLocalizedString("new_habit.enter_name", comment: "Введите название трекера"),
        maxCharacters: 38
    )
    private let tableContainer = ContainerTableView()

    private lazy var emojiCollectionVC = SelectableCollectionViewController(
        items: CollectionData.emojis,
        headerTitle: NSLocalizedString("new_habit.emoji", comment: "Emoji")
    )

    private lazy var colorCollectionVC = SelectableCollectionViewController(
        items: CollectionData.colors,
        headerTitle: NSLocalizedString("new_habit.color", comment: "Цвет")
    )

    private let bottomButtons = ButonsPanelView()
    private let context = CoreDataStack.shared.context

    // MARK: - State
    private var selectedDays: [WeekDay] = []
    private var selectedEmoji: String?
    private var selectedColor: UIColor?
    private var selectedCategory: TrackerCategoryCoreData?

    // MARK: - Lifecycle
    init(viewModel: EditHabitViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        // Инициализация состояния из viewModel
        self.selectedEmoji = viewModel.tracker.emoji
        if let hex = viewModel.tracker.color {
            self.selectedColor = UIColor(named: hex)
        }
        self.selectedDays = viewModel.tracker.decodedSchedule
        self.selectedCategory = viewModel.tracker.category
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background

        setupTable()
        setupLayout()
        setupActions()
        setupInitialValues()
    }

    // MARK: - Setup initial UI values
    private func setupInitialValues() {
        nameTextField.setText(viewModel.tracker.name ?? "")
        
        bottomButtons.createButton.setTitle(
            NSLocalizedString("edit_habit.save", comment: "Сохранить"),
            for: .normal
        )
        
        // 🔹 Устанавливаем количество дней
        let daysCount = viewModel.tracker.decodedSchedule.count
                daysCountLabel.text = "\(daysCount) \(russianDayForm(daysCount))"
        
        // Обработка выбора эмодзи
        emojiCollectionVC.onItemSelected = { [weak self] item in
            if let emojiItem = item as? CollectionItem, case .emoji(let emoji) = emojiItem {
                self?.selectedEmoji = emoji
            }
        }

        // Обработка выбора цвета
        colorCollectionVC.onItemSelected = { [weak self] item in
            if let colorItem = item as? CollectionItem, case .color(let color) = colorItem {
                self?.selectedColor = color
            }
        }

        // Обновление кнопки "Сохранить" при изменении текста
        nameTextField.onTextChanged = { [weak self] text in
            let hasText = !text.trimmingCharacters(in: .whitespaces).isEmpty
            self?.bottomButtons.setCreateButton(enabled: hasText)
        }
    }
    
    private func russianDayForm(_ n: Int) -> String {
        let nAbs = abs(n) % 100
        let n1 = nAbs % 10
        if nAbs > 10 && nAbs < 20 {
            return "дней"
        }
        if n1 == 1 {
            return "день"
        }
        if n1 >= 2 && n1 <= 4 {
            return "дня"
        }
        return "дней"
    }

    // MARK: - Helpers
    private func localizedDays(for count: Int) -> String {
        let formatString = NSLocalizedString("edit_habit.days_count", comment: "Количество дней")
        return String.localizedStringWithFormat(formatString, count)
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

        // 🔹 Добавляем лейбл количества дней между заголовком и полем ввода
        [daysCountLabel, nameTextField, tableContainer, emojiCollectionVC.view, colorCollectionVC.view].forEach {
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

            daysCountLabel.heightAnchor.constraint(equalToConstant: 40),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),
            tableContainer.heightAnchor.constraint(equalToConstant: 150),
            emojiCollectionVC.view.heightAnchor.constraint(equalToConstant: 300),
            colorCollectionVC.view.heightAnchor.constraint(equalToConstant: 200)
        ])
    }

    // MARK: - Actions
    private func setupActions() {
        bottomButtons.cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        bottomButtons.createButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        let title = nameTextField.textValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        guard let emoji = selectedEmoji else { return }
        guard let color = selectedColor else { return }
        guard let category = selectedCategory else { return }

        let tracker = viewModel.tracker
        tracker.name = title
        tracker.emoji = emoji
        tracker.color = color.toHexString()
        tracker.category = category
        tracker.decodedSchedule = selectedDays

        do {
            try context.save()
            dismiss(animated: true)
        } catch {
            print("❌ Ошибка сохранения трекера: \(error.localizedDescription)")
        }
    }
}

// MARK: - UITableView
extension EditHabitViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 2 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContainerTableViewCell

        if indexPath.row == 0 {
            cell.configure(
                title: NSLocalizedString("new_habit.category", comment: "Категория"),
                detail: selectedCategory?.title
            )
        } else {
            let detailText = selectedDays.isEmpty ? nil : selectedDays.descriptionText
            cell.configure(
                title: NSLocalizedString("new_habit.schedule", comment: "Расписание"),
                detail: detailText
            )
        }
        cell.isLastCell = indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.row == 0 {
            let categoryVC = CategoryViewController(store: TrackerCategoryStore(context: context))
            categoryVC.onCategorySelected = { [weak self] category in
                self?.selectedCategory = category
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            if let sheet = categoryVC.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 16
            }
            present(categoryVC, animated: true)
        }

        if indexPath.row == 1 {
            let scheduleVC = ScheduleViewController()
            scheduleVC.selectedDays = selectedDays

            scheduleVC.onDone = { [weak self] days in
                self?.selectedDays = days
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }

            if let sheet = scheduleVC.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 16
            }
            present(scheduleVC, animated: true)
        }
    }
}
