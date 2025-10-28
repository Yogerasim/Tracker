import UIKit
import Combine

final class TrackersViewController: UIViewController {
    
    
    let viewModel: TrackersViewModel
    let ui = TrackersUI()
    
    private let placeholderView = PlaceholderView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    let filtersViewModel: FiltersViewModel
    var contextMenuController: BaseContextMenuController<TrackerCell>?
    
    
    init(viewModel: TrackersViewModel = TrackersViewModel()) {
        self.viewModel = viewModel
        let dateFilter = TrackersDateFilter()
        
        self.filtersViewModel = FiltersViewModel(
            trackersProvider: { viewModel.trackers },
            isCompletedProvider: { tracker, date in
                viewModel.isTrackerCompleted(tracker, on: date)
            },
            dateFilter: dateFilter
        )
        
        super.init(nibName: nil, bundle: nil)
        AppLogger.trackers.info("[VC] 🧩 TrackersViewController init()")
    }
    
    required init?(coder: NSCoder) {
        let viewModel = TrackersViewModel()
        self.viewModel = viewModel
        let dateFilter = TrackersDateFilter()
        
        self.filtersViewModel = FiltersViewModel(
            trackersProvider: { viewModel.trackers },
            isCompletedProvider: { tracker, date in
                viewModel.isTrackerCompleted(tracker, on: date)
            },
            dateFilter: dateFilter
        )
        super.init(coder: coder)
        AppLogger.trackers.info("[VC] 🧩 TrackersViewController init(coder:)")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        AppLogger.trackers.info("[VC] 🚀 viewDidLoad()")
        
        registerCollectionViewCells()
        setupNavigationBarButtons()
        setupLayout()
        setupPlaceholder()
        setupCalendarContainer()
        setupBindings()
        updateDateText()
        setupContextMenuController()
        setupSearchBar()
        setupTapGesture()
        setupLoadingIndicator()
        updateColorsForCurrentTraitCollection()
        viewModel.loadData()
        if let savedIndex = UserDefaults.standard.value(forKey: "selectedFilterIndex") as? Int {
            filtersViewModel.selectFilter(index: savedIndex)
            AppLogger.trackers.info("[VC] 🎛 selectedFilterIndex восстановлен: \(savedIndex)")
        } else {
            filtersViewModel.selectFilter(index: 0)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppLogger.trackers.info("[VC] 👁 viewDidAppear()")
        AnalyticsService.trackOpen(screen: "Main")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AppLogger.trackers.info("[VC] 💤 viewWillDisappear()")
        AnalyticsService.trackClose(screen: "Main")
    }
    
    
    private func updateColorsForCurrentTraitCollection() {
        view.backgroundColor = AppColors.background
        ui.collectionView.backgroundColor = AppColors.background
        ui.searchBar.searchTextField.backgroundColor = AppColors.background
        ui.searchBar.searchTextField.textColor = AppColors.textPrimary
        ui.dateButton.backgroundColor = AppColors.textSecondary.withAlphaComponent(0.1)
        ui.dateButton.setTitleColor(AppColors.textPrimary, for: .normal)
        ui.calendarContainer.backgroundColor = AppColors.background
    }
    
    private func registerCollectionViewCells() {
        ui.collectionView.register(
            TrackerSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: TrackerSectionHeaderView.reuseIdentifier
        )
        ui.collectionView.register(
            TrackerCell.self,
            forCellWithReuseIdentifier: TrackerCell.reuseIdentifier
        )
        ui.collectionView.dataSource = self
        ui.collectionView.delegate = self
        AppLogger.trackers.debug("[VC] 🧱 Коллекция зарегистрирована")
    }
    
    private func setupNavigationBarButtons() {
        ui.addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        let container = UIView()
        container.addSubview(ui.addButton)
        ui.addButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ui.addButton.topAnchor.constraint(equalTo: container.topAnchor),
            ui.addButton.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ui.addButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            ui.addButton.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: container)
    }
    
    private func setupLayout() {
        [ui.titleView, ui.dateButton, ui.searchBar, ui.collectionView, ui.filtersButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            ui.titleView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            ui.titleView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            ui.dateButton.centerYAnchor.constraint(equalTo: ui.titleView.centerYAnchor),
            ui.dateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            ui.searchBar.topAnchor.constraint(equalTo: ui.titleView.bottomAnchor, constant: 8),
            ui.searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            ui.searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            ui.collectionView.topAnchor.constraint(equalTo: ui.searchBar.bottomAnchor, constant: 8),
            ui.collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            ui.collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            ui.collectionView.bottomAnchor.constraint(equalTo: ui.filtersButton.topAnchor, constant: -8),
            ui.filtersButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ui.filtersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            ui.filtersButton.widthAnchor.constraint(equalToConstant: 114),
            ui.filtersButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        ui.filtersButton.addTarget(self, action: #selector(filtersTapped), for: .touchUpInside)
        ui.dateButton.addTarget(self, action: #selector(toggleCalendar), for: .touchUpInside)
    }
    
    
    private func setupPlaceholder() {
        view.addSubview(ui.placeholderView)
        ui.placeholderView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ui.placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ui.placeholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        ui.placeholderView.configure(
            imageName: "Star",
            text: NSLocalizedString("trackers.placeholder_text", comment: "")
        )
        updatePlaceholder()
    }
    
    func updatePlaceholder() {
        let hasTrackers = !filtersViewModel.filteredTrackers.isEmpty
        ui.placeholderView.isHidden = hasTrackers
        ui.collectionView.isHidden = !hasTrackers
        ui.filtersButton.isHidden = !hasTrackers
        AppLogger.trackers.debug("[UI] 🪶 updatePlaceholder() hidden=\(!hasTrackers)")
    }
    func updateDateText() {
        let df = DateFormatter()
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        
        switch languageCode {
        case "ru":
            df.locale = Locale(identifier: "ru_RU")
            df.dateFormat = "dd.MM.yy"
        case "fr":
            df.locale = Locale(identifier: "fr_FR")
            df.dateFormat = "dd/MM/yy"
        default:
            df.locale = Locale(identifier: "en_US")
            df.dateFormat = "MM/dd/yy"
        }
        let text = df.string(from: viewModel.currentDate)
        ui.dateButton.setTitle(df.string(from: viewModel.currentDate), for: .normal)
        AppLogger.trackers.debug("[UI] 📅 updateDateText() = \(text)")
    }
    
    func editTracker(_ trackerCoreData: TrackerCoreData) {
        guard let context = trackerCoreData.managedObjectContext else { return }
        guard let editVM = EditHabitViewModel(tracker: trackerCoreData, context: context) else { return }
        let editVC = EditHabitViewController(viewModel: editVM)
        
        editVM.onHabitEdited = { [weak self] in
            guard let self else { return }
            let updatedTracker = Tracker(
                id: trackerCoreData.id ?? UUID(),
                name: trackerCoreData.name ?? "",
                color: trackerCoreData.color ?? "FFFFFF",
                emoji: trackerCoreData.emoji ?? "",
                schedule: (trackerCoreData.schedule as? Data).flatMap {
                    try? JSONDecoder().decode([WeekDay].self, from: $0)
                } ?? [],
                trackerCategory: trackerCoreData.category
            )
            self.viewModel.editTracker(updatedTracker)
            self.ui.collectionView.reloadData()
        }
        present(editVC, animated: true)
    }
    
    func confirmDeleteTracker(_ tracker: Tracker) {
        let alert = UIAlertController(
            title: NSLocalizedString("tracker.action.delete_alert_title", comment: "Delete tracker title"),
            message: NSLocalizedString("tracker.action.delete_alert_message", comment: "Delete tracker message"),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("tracker.action.delete", comment: "Delete tracker button"),
            style: .destructive
        ) { [weak self] _ in
            self?.viewModel.deleteTracker(tracker)
            AnalyticsService.trackClick(item: "delete")
        })
        
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("tracker.action.cancel", comment: "Cancel button"),
            style: .cancel
        ))
        
        present(alert, animated: true)
    }
    
    
    private func setupCalendarContainer() {
        view.addSubview(ui.calendarContainer)
        ui.calendarContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ui.calendarContainer.topAnchor.constraint(equalTo: ui.dateButton.bottomAnchor, constant: 8),
            ui.calendarContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ui.calendarContainer.widthAnchor.constraint(equalToConstant: 350),
            ui.calendarContainer.heightAnchor.constraint(equalToConstant: 320)
        ])
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        let localeIdentifier: String
        
        switch languageCode {
        case "ru": localeIdentifier = "ru_RU"
        case "fr": localeIdentifier = "fr_FR"
        default: localeIdentifier = "en_GB"
        }
        
        let locale = Locale(identifier: localeIdentifier)
        ui.calendarView.locale = locale
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        ui.calendarView.calendar = calendar
        
        ui.calendarView.addTarget(self, action: #selector(calendarDateChanged(_:)), for: .valueChanged)
    }
    
    
    private func setupBindings() {
        viewModel.onTrackersUpdated = { [weak self] in
            guard let self = self else { return }

            AppLogger.trackers.debug("[UI] 🔁 onTrackersUpdated() вызван")

            // 1️⃣ Обновляем фильтры и категории перед UI-обновлением
            self.filtersViewModel.applyFilter()
            self.recalculateVisibleCategories()

            // 2️⃣ Проверяем, есть ли обновлённый трекер
            guard let updatedID = self.viewModel.lastUpdatedTrackerID else {
                AppLogger.trackers.debug("[UI] ⚠️ lastUpdatedTrackerID отсутствует → выполняем полное обновление")
                self.ui.collectionView.reloadData()
                return
            }

            // 3️⃣ Находим IndexPath конкретного трекера
            let allVisibleTrackers = self.filtersViewModel.filteredTrackers

            guard let tracker = allVisibleTrackers.first(where: { $0.id == updatedID }) else {
                AppLogger.trackers.debug("[UI] ⚠️ Обновлённый трекер отсутствует в фильтре → reloadData()")
                self.ui.collectionView.reloadData()
                return
            }

            let categoryTitle = tracker.trackerCategory?.title ?? "Мои трекеры"

            guard let sectionIndex = self.visibleCategories.firstIndex(where: { $0.title == categoryTitle }) else {
                AppLogger.trackers.debug("[UI] ⚠️ Категория '\(categoryTitle)' не найдена → reloadData()")
                self.ui.collectionView.reloadData()
                return
            }

            let trackersInSection = allVisibleTrackers.filter {
                $0.trackerCategory?.title == categoryTitle
            }

            guard let itemIndex = trackersInSection.firstIndex(where: { $0.id == updatedID }) else {
                AppLogger.trackers.debug("[UI] ⚠️ Трекер не найден в своей категории → reloadData()")
                self.ui.collectionView.reloadData()
                return
            }

            let indexPath = IndexPath(item: itemIndex, section: sectionIndex)

            // 4️⃣ Логируем для отладки
            AppLogger.trackers.debug("[UI] ✅ Обновляем одну ячейку → \(indexPath) [\(tracker.name)]")

            // 5️⃣ Безопасное обновление UI
            DispatchQueue.main.async {
                UIView.performWithoutAnimation {
                    self.ui.collectionView.reloadItems(at: [indexPath])
                }
            }
        }

        viewModel.onCategoriesUpdated = { [weak self] in
            guard let self = self else { return }
            AppLogger.trackers.info("[VM→UI] 🗂 onCategoriesUpdated")
            self.scheduleUIRefresh()
        }

        viewModel.onDateChanged = { [weak self] date in
            guard let self = self else { return }
            AppLogger.trackers.info("[VM→UI] 📆 onDateChanged → \(date)")
            self.filtersViewModel.selectFilter(index: self.filtersViewModel.selectedFilterIndex)
            self.scheduleUIRefresh()
        }

        filtersViewModel.onFilteredTrackersUpdated = { [weak self] in
            guard let self = self else { return }
            AppLogger.trackers.info("[Filter→UI] 🔍 onFilteredTrackersUpdated")
            self.scheduleUIRefresh()
        }
    }
    
    private var uiUpdateWorkItem: DispatchWorkItem?
    private var lastUIReloadTime: Date?

    private func scheduleUIRefresh() {
        uiUpdateWorkItem?.cancel()

        let now = Date()
        if let last = lastUIReloadTime, now.timeIntervalSince(last) < 0.2 {
            AppLogger.trackers.debug("[UI] ⏸ Пропущен reload — слишком частый вызов")
            return
        }
        lastUIReloadTime = now

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            AppLogger.trackers.debug("[UI] ♻️ scheduleUIRefresh() → reload collection")
            self.recalculateVisibleCategories()
            self.ui.collectionView.reloadData()
            self.updatePlaceholder()
        }
        uiUpdateWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
    }
    
    
    @objc private func addButtonTapped() {
        AppLogger.trackers.info("[UI] ➕ addButtonTapped()")
        let createVC = CreateTrackerViewController()
        present(createVC, animated: true)
    }
    
    @objc private func toggleCalendar() {
        ui.calendarContainer.isHidden.toggle()
        AppLogger.trackers.debug("[UI] 📅 toggleCalendar → isHidden = \(ui.calendarContainer.isHidden)")
        if !ui.calendarContainer.isHidden {
            view.bringSubviewToFront(ui.calendarContainer)
        }
    }
    
    @objc private func calendarDateChanged(_ sender: UIDatePicker) {
        AppLogger.trackers.info("[UI] 📆 calendarDateChanged() → \(sender.date)")
        ui.calendarContainer.isHidden = true
        viewModel.currentDate = sender.date
        filtersViewModel.applyFilter(for: sender.date)
    }
    
    @objc private func filtersTapped() {
        AppLogger.trackers.info("[UI] 🧩 filtersTapped()")
        let filtersVC = FiltersViewController(viewModel: filtersViewModel)
        filtersVC.onFilterSelected = { [weak self] index in
            guard let self else { return }
            if index == 1 { 
                self.showTodayTrackers()
            } else {
                self.filtersViewModel.selectFilter(index: index)
            }
        }
        presentFullScreenSheet(filtersVC)
    }
    
    func showTodayTrackers() {
        let today = Date()
        ui.calendarView.setDate(today, animated: true)
        AppLogger.trackers.info("[UI] 🕒 showTodayTrackers() = \(today)")
        viewModel.currentDate = today
        filtersViewModel.selectFilter(index: filtersViewModel.selectedFilterIndex)
        ui.collectionView.reloadData()
    }
    
    
    private func setupSearchBar() {
        ui.searchBar.delegate = self
    }
    
    
    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    
    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func handleScreenTap(_ sender: UITapGestureRecognizer) {
        if !ui.calendarContainer.isHidden {
            ui.calendarContainer.isHidden = true
        }
    }
    
    
    private func setupContextMenuController() {
        contextMenuController = BaseContextMenuController(
            owner: self,
            container: ui.collectionView,
            indexPathProvider: { [weak self] cell in
                self?.ui.collectionView.indexPath(for: cell)
            },
            actionsProvider: { [weak self] indexPath in
                guard let self else { return [] }
                guard self.visibleCategories.indices.contains(indexPath.section) else { return [] }
                let category = self.visibleCategories[indexPath.section]
                let trackersInCategory = self.filtersViewModel.filteredTrackers.filter {
                    $0.trackerCategory?.title == category.title
                }
                guard trackersInCategory.indices.contains(indexPath.item) else { return [] }
                
                let tracker = trackersInCategory[indexPath.item]
                let isPinned = tracker.trackerCategory?.title == self.viewModel.pinnedCategoryTitle
                
                let pinTitle = isPinned
                ? NSLocalizedString("tracker.action.unpin", comment: "Открепить трекер")
                : NSLocalizedString("tracker.action.pin", comment: "Закрепить трекер")
                let pinAction = UIAction(title: pinTitle, image: UIImage(systemName: isPinned ? "pin.slash" : "pin")) { _ in
                    isPinned ? self.viewModel.unpinTracker(tracker) : self.viewModel.pinTracker(tracker)
                }
                
                let editAction = UIAction(title: NSLocalizedString("tracker.action.edit", comment: "Редактировать трекер"), image: UIImage(systemName: "pencil")) { [weak self] _ in
                    guard let self = self else { return }
                    guard let trackerCoreData = self.viewModel.trackerStore.fetchTracker(by: tracker.id) else { return }
                    self.editTracker(trackerCoreData)
                    AnalyticsService.trackClick(item: "edit")
                }
                
                let deleteAction = UIAction(title: NSLocalizedString("tracker.action.delete", comment: "Удалить трекер"), image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                    guard let self = self else { return }
                    self.confirmDeleteTracker(tracker)
                    AnalyticsService.trackClick(item: "delete")
                }
                
                return [pinAction, editAction, deleteAction]
            }
        )
    }
    
    
    var visibleCategories: [TrackerCategory] = []
    
    func recalculateVisibleCategories() {
        visibleCategories = viewModel.categories.filter { category in
            filtersViewModel.filteredTrackers.contains { tracker in
                (tracker.trackerCategory?.title ?? "Мои трекеры") == category.title
            }
        }
        AppLogger.trackers.debug("[UI] 📊 recalculateVisibleCategories() count = \(visibleCategories.count)")
    }
}


extension TrackersViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        AppLogger.trackers.debug("[UI] 🔎 searchTextChanged → \(searchText)")
        filtersViewModel.searchText = searchText
        updatePlaceholder()
    }
}

extension TrackersViewController {
    func updateUI() {
        AppLogger.trackers.debug("[UI] 🔄 updateUI()")
        scheduleUIRefresh()
        updatePlaceholder()
        updateDateText()
    }
}
