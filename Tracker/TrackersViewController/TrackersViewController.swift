import UIKit
import Combine

final class TrackersViewController: UIViewController {
    
    // MARK: - ViewModel
    let viewModel: TrackersViewModel
    let ui = TrackersUI()
    
    private let titleView = MainTitleLabelView(title: NSLocalizedString("trackers.title", comment: "Заголовок главного экрана трекеров"))
    private let placeholderView = PlaceholderView()
    
    // MARK: - Init
    init(viewModel: TrackersViewModel = TrackersViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        self.viewModel = TrackersViewModel()
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColors.background
        
        // Регистрация ячеек
        ui.collectionView.register(
            TrackerSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: TrackerSectionHeaderView.reuseIdentifier
        )
        ui.collectionView.register(
            TrackerCell.self,
            forCellWithReuseIdentifier: TrackerCell.reuseIdentifier
        )
        
        // Перемещаем кнопки в navigationBar
        setupNavigationBarButtons()
        
        // Остальные элементы остаются в view
        [ui.titleView, ui.searchBar, ui.collectionView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        setupLayoutForRest() // layout для titleView, searchBar, collectionView
        
        ui.collectionView.dataSource = self
        ui.collectionView.delegate = self
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        ui.collectionView.addGestureRecognizer(longPress)
        
        ui.filtersButton.addTarget(self, action: #selector(filtersTapped), for: .touchUpInside)
        
        setupCalendarContainer()
        setupPlaceholder()
        bindViewModel()
        viewModel.ensureDefaultCategory()
        
        updateUI()
        updatePlaceholder()
        updateDateText()
        
        ui.searchBar.delegate = self
        ui.searchBar.barTintColor = AppColors.background
        ui.searchBar.searchTextField.backgroundColor = AppColors.background
        ui.searchBar.searchTextField.textColor = AppColors.textPrimary
        ui.searchBar.searchTextField.tintColor = AppColors.primaryBlue
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsService.shared.trackOpen(screen: "Main")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AnalyticsService.shared.trackClose(screen: "Main")
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Фон экрана
        view.backgroundColor = AppColors.background
        // Коллекция
        ui.collectionView.backgroundColor = AppColors.background
        // Поисковая строка
        ui.searchBar.barTintColor = AppColors.background
        ui.searchBar.searchTextField.backgroundColor = AppColors.background
        ui.searchBar.searchTextField.textColor = AppColors.textPrimary
        // Кнопка даты
        ui.dateButton.backgroundColor = AppColors.textSecondary.withAlphaComponent(0.1)
        ui.dateButton.setTitleColor(AppColors.textPrimary, for: .normal)
        // Календарь
        ui.calendarContainer.backgroundColor = AppColors.background
        ui.calendarView.backgroundColor = AppColors.background
    }
    
    // MARK: - Layout
    private func setupNavigationBarButtons() {
        // "+" кнопка
        ui.addButton.translatesAutoresizingMaskIntoConstraints = false
        ui.addButton.widthAnchor.constraint(equalToConstant: 42).isActive = true
        ui.addButton.heightAnchor.constraint(equalToConstant: 42).isActive = true
        ui.addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        let addItem = UIBarButtonItem(customView: ui.addButton)
        navigationItem.leftBarButtonItem = addItem
        
        // Кнопка даты
        ui.dateButton.translatesAutoresizingMaskIntoConstraints = false
        ui.dateButton.widthAnchor.constraint(equalToConstant: 77).isActive = true
        ui.dateButton.heightAnchor.constraint(equalToConstant: 34).isActive = true
        ui.dateButton.addTarget(self, action: #selector(toggleCalendar), for: .touchUpInside)
        let dateItem = UIBarButtonItem(customView: ui.dateButton)
        navigationItem.rightBarButtonItem = dateItem
        
        // Убираем стандартный title, если нужно
        navigationItem.titleView = nil
    }
    
    private func setupLayoutForRest() {
        // MARK: - Добавляем кнопки в navigationBar
        let addButtonItem = UIBarButtonItem(customView: ui.addButton)
        let dateButtonItem = UIBarButtonItem(customView: ui.dateButton)
        
        // Принудительно задаём размеры
        ui.addButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ui.addButton.widthAnchor.constraint(equalToConstant: 42),
            ui.addButton.heightAnchor.constraint(equalToConstant: 42)
        ])
        
        ui.dateButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ui.dateButton.widthAnchor.constraint(equalToConstant: 77),
            ui.dateButton.heightAnchor.constraint(equalToConstant: 34)
        ])
        
        navigationItem.leftBarButtonItem = addButtonItem
        navigationItem.rightBarButtonItem = dateButtonItem

        // MARK: - Layout для остальных элементов
        [ui.titleView, ui.searchBar, ui.collectionView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        view.addSubview(ui.filtersButton)
        NSLayoutConstraint.activate([
            ui.filtersButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ui.filtersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            ui.filtersButton.widthAnchor.constraint(equalToConstant: 114),
            ui.filtersButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        NSLayoutConstraint.activate([
            // Заголовок под navigationBar (используем safeArea)
            ui.titleView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            ui.titleView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),

            // Поиск под заголовком
            ui.searchBar.topAnchor.constraint(equalTo: ui.titleView.bottomAnchor, constant: 2),
            ui.searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            ui.searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Коллекция под поиском
            ui.collectionView.topAnchor.constraint(equalTo: ui.searchBar.bottomAnchor, constant: 8),
            ui.collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            ui.collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            ui.collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Placeholder
    private func setupPlaceholder() {
        // Добавляем на главный view, чтобы центр был по экрану
        view.addSubview(ui.placeholderView)
        
        ui.placeholderView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ui.placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ui.placeholderView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        
        ui.placeholderView.configure(
            imageName: "Star",
            text: NSLocalizedString("trackers.placeholder_text", comment: "Текст при отсутствии трекеров")
        )
        
        updatePlaceholder()
    }
    
    func setupCalendarContainer() {
        view.addSubview(ui.calendarContainer)
        ui.calendarContainer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            ui.calendarContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            ui.calendarContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ui.calendarContainer.widthAnchor.constraint(equalToConstant: 343),
            ui.calendarContainer.heightAnchor.constraint(equalToConstant: 325)
        ])
    }
    
    func updatePlaceholder() {
        let hasTrackers = !viewModel.filteredTrackers.isEmpty
        ui.placeholderView.isHidden = hasTrackers
        ui.collectionView.isHidden = !hasTrackers
        
        if !hasTrackers {
            let searchText = ui.searchBar.text ?? ""
            if !searchText.isEmpty {
                ui.placeholderView.configure(
                    imageName: "NoSearch",
                    text: NSLocalizedString("trackers.placeholder_no_results", comment: "Текст при отсутствии результатов поиска")
                )
            } else {
                ui.placeholderView.configure(
                    imageName: "Star",
                    text: NSLocalizedString("trackers.placeholder_text", comment: "Текст при отсутствии трекеров")
                )
            }
        }
    }
    
    func updateDateText() {
        let df = DateFormatter()
        
        // Получаем язык устройства (iOS 16+)
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        
        switch languageCode {
        case "ru":
            df.locale = Locale(identifier: "ru_RU")
            df.dateFormat = "dd.MM.yy"
        case "fr":
            df.locale = Locale(identifier: "fr_FR")
            df.dateFormat = "dd/MM/yy"
        default: // английский
            df.locale = Locale(identifier: "en_US")
            df.dateFormat = "MM/dd/yy"
        }
        
        ui.dateButton.setTitle(df.string(from: viewModel.currentDate), for: .normal)
    }
    
    // MARK: - Binding
    
    private func setupBindings() {
        viewModel.onTrackersUpdated = { [weak self] in
            self?.updateUI()
        }
    }
    
    
    // MARK: - UI Update Debounce
    private var uiUpdateWorkItem: DispatchWorkItem?
    
    private func bindViewModel() {
        
        // Общая функция для отложенного обновления UI
        func scheduleUIRefresh(reason: String) {
            // Отменяем предыдущую задачу, если она ещё не выполнена
            uiUpdateWorkItem?.cancel()
            
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                
                // Пересчёт visibleCategories прямо перед reloadData
                self.recalculateVisibleCategories()
                
                print("🔁 UI Refresh triggered by: \(reason)")
                print("🔁 visibleCategories: \(self.visibleCategories.map { $0.title })")
                
                // Проверка, что collectionView в иерархии
                guard self.ui.collectionView.window != nil else {
                    print("⚠️ collectionView не в иерархии, reloadData пропущен")
                    return
                }
                
                self.ui.collectionView.reloadData()
                self.updatePlaceholder()
            }
            
            uiUpdateWorkItem = workItem
            // Выполняем с небольшим дебаунсом, чтобы сгладить множественные обновления
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
        }
        
        // Единый обработчик всех обновлений
        let refreshUI = { [weak self] (reason: String) in
            guard let self = self else { return }
            scheduleUIRefresh(reason: reason)
        }
        
        // Подписки на события ViewModel
        viewModel.onTrackersUpdated = { refreshUI("Trackers Updated") }
        viewModel.onCategoriesUpdated = { refreshUI("Categories Updated") }
        viewModel.onDateChanged = { date in
            refreshUI("Date Changed")
            print("🔁 onDateChanged called: \(date)")
        }
        
        viewModel.onEditTracker = { [weak self] tracker in
            guard let self = self else { return }
            print("🖋 onEditTracker called for: \(tracker.name)")
            
            guard let trackerCoreData = self.viewModel.trackerStore.fetchTracker(by: tracker.id) else {
                print("❌ Не удалось найти TrackerCoreData для \(tracker.name)")
                return
            }
            self.editTracker(trackerCoreData)
        }
    }
    
    // MARK: - Visible Categories
    var visibleCategories: [TrackerCategory] = []
    
    private func recalculateVisibleCategories() {
        visibleCategories = viewModel.categories.filter { category in
            viewModel.filteredTrackers.contains { tracker in
                (tracker.trackerCategory?.title ?? "Мои трекеры") == category.title
            }
        }
    }
    
    // MARK: - UpdatUI
    func updateUI() {
        // Пересчёт перед обновлением UI
        recalculateVisibleCategories()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Проверка, что collectionView в иерархии
            guard self.ui.collectionView.window != nil else {
                print("⚠️ collectionView не в иерархии, reloadData пропущен")
                return
            }
            
            print("🔁 updateUI -> visibleCategories: \(self.visibleCategories.map { $0.title })")
            print("🧩 reloadData called, filteredTrackers:", self.viewModel.filteredTrackers.count)
            self.ui.collectionView.reloadData()
        }
    }
    
    // MARK: - Actions
    @objc func addButtonTapped() {
        AnalyticsService.shared.trackClick(item: "add_track", screen: "Main")
        let createTrackerVC = CreateTrackerViewController()
        createTrackerVC.onTrackerCreated = { [weak self] tracker in
            self?.viewModel.addTrackerToDefaultCategory(tracker)
        }
        present(createTrackerVC, animated: true)
    }
    
    @objc func toggleCalendar() {
        ui.calendarContainer.isHidden.toggle()
        
        if !ui.calendarContainer.isHidden {
            view.bringSubviewToFront(ui.calendarContainer)
        }
    }
    
    @objc func calendarDateChanged(_ sender: UIDatePicker) {
        viewModel.currentDate = sender.date
        updateDateText()
        viewModel.filterByDate() // включает фильтрацию по дате
        ui.collectionView.reloadData()
    }
    
    @objc private func filtersTapped() {
        AnalyticsService.shared.trackClick(item: "filter", screen: "Main")
        let filtersVC = FiltersViewController()
        filtersVC.onFilterSelected = { [weak self] index in
            guard let self = self else { return }
            self.viewModel.selectedFilterIndex = index
            print("🧩 reloadData called, filteredTrackers:", self.viewModel.filteredTrackers.count)
            self.ui.collectionView.reloadData()
        }
        filtersVC.modalPresentationStyle = .pageSheet
        present(filtersVC, animated: true)
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: ui.collectionView)
        guard let indexPath = ui.collectionView.indexPathForItem(at: location),
              let cell = ui.collectionView.cellForItem(at: indexPath) else { return }

        guard visibleCategories.indices.contains(indexPath.section) else { return }
        let category = visibleCategories[indexPath.section]

        let trackersInCategory = viewModel.filteredTrackers.filter { tracker in
            tracker.trackerCategory?.title == category.title ||
            (tracker.trackerCategory == nil && category.title == NSLocalizedString("trackers.default_category", comment: "My Trackers"))
        }

        guard trackersInCategory.indices.contains(indexPath.item) else { return }
        let tracker = trackersInCategory[indexPath.item]

        let isPinned = tracker.trackerCategory?.title == viewModel.pinnedCategoryTitle

        ActionMenuPresenter.show(for: cell, in: self, actions: [
            .init(title: isPinned ? NSLocalizedString("tracker.action.unpin", comment: "Unpin") :
                                     NSLocalizedString("tracker.action.pin", comment: "Pin"),
                  style: .default) { [weak self] in
                guard let self = self else { return }
                if isPinned {
                    self.viewModel.unpinTracker(tracker)
                } else {
                    self.viewModel.pinTracker(tracker)
                }
            },
            .init(title: NSLocalizedString("tracker.action.edit", comment: "Edit"), style: .default) { [weak self] in
                guard let self = self else { return }
                AnalyticsService.shared.trackClick(item: "edit", screen: "Main")
                self.viewModel.editTracker(tracker)
            },
            .init(title: NSLocalizedString("tracker.action.delete", comment: "Delete"), style: .destructive) { [weak self] in
                guard let self = self else { return }
                AnalyticsService.shared.trackClick(item: "delete", screen: "Main")
                let alert = UIAlertController(
                    title: NSLocalizedString("tracker.action.delete_alert_title", comment: "Delete tracker?"),
                    message: NSLocalizedString("tracker.action.delete_alert_message", comment: "This action cannot be undone."),
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: NSLocalizedString("tracker.action.delete", comment: "Delete"), style: .destructive) { _ in
                    self.viewModel.deleteTracker(tracker)
                })
                alert.addAction(UIAlertAction(title: NSLocalizedString("tracker.action.cancel", comment: "Cancel"), style: .cancel))
                self.present(alert, animated: true)
            }
        ])
    }
    
    func togglePin(for tracker: Tracker) {
        if tracker.trackerCategory?.title == viewModel.pinnedCategoryTitle {
            viewModel.unpinTracker(tracker)
        } else {
            viewModel.pinTracker(tracker)
        }
    }
    
    func editTracker(_ tracker: TrackerCoreData) {
        guard let context = tracker.managedObjectContext else {
            print("❌ Ошибка: у трекера нет context")
            return
        }
        
        guard let editVM = EditHabitViewModel(tracker: tracker, context: context) else {
            print("❌ Ошибка: не удалось создать EditHabitViewModel")
            print("Текущие данные трекера:")
            print("name: \(tracker.name ?? "nil")")
            print("emoji: \(tracker.emoji ?? "nil")")
            print("color: \(tracker.color ?? "nil")")
            print("category: \(tracker.category?.title ?? "nil")")
            return
        }
        
        print("✅ EditHabitViewModel создан успешно для трекера: \(tracker.name ?? "nil")")
        
        let editVC = EditHabitViewController(viewModel: editVM)
        present(editVC, animated: true) {
            print("✅ EditHabitViewController представлен")
        }
    }
    
    func deleteTracker(_ tracker: Tracker) {
        let alert = UIAlertController(title: "Удалить трекер?", message: "Это действие нельзя отменить.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteTracker(tracker)
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
}
extension TrackersViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchText = searchText
        updatePlaceholder()
    }
}




