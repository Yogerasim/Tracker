import Combine
import UIKit
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
        filtersViewModel = FiltersViewModel(
            trackersProvider: { viewModel.trackers },
            isCompletedProvider: { tracker, date in
                viewModel.isTrackerCompleted(tracker, on: date)
            },
            dateFilter: dateFilter
        )
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        let viewModel = TrackersViewModel()
        self.viewModel = viewModel
        let dateFilter = TrackersDateFilter()
        filtersViewModel = FiltersViewModel(
            trackersProvider: { viewModel.trackers },
            isCompletedProvider: { tracker, date in
                viewModel.isTrackerCompleted(tracker, on: date)
            },
            dateFilter: dateFilter
        )
        super.init(coder: coder)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
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
        reloadFromCoreData()
        viewModel.loadData()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsService.trackOpen(screen: "Main")
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AnalyticsService.trackClose(screen: "Main")
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
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
            ui.addButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: container)
    }
    private func setupLayout() {
        for item in [ui.titleView, ui.dateButton, ui.searchBar, ui.collectionView, ui.filtersButton] {
            view.addSubview(item)
            item.translatesAutoresizingMaskIntoConstraints = false
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
            ui.collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ui.filtersButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ui.filtersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            ui.filtersButton.widthAnchor.constraint(equalToConstant: 114),
            ui.filtersButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        ui.filtersButton.addTarget(self, action: #selector(filtersTapped), for: .touchUpInside)
        ui.dateButton.addTarget(self, action: #selector(toggleCalendar), for: .touchUpInside)
        ui.collectionView.contentInset = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: 50,
            right: 0
        )
        ui.collectionView.scrollIndicatorInsets = ui.collectionView.contentInset
    }
    private func setupPlaceholder() {
        view.addSubview(ui.placeholderView)
        ui.placeholderView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ui.placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ui.placeholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
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
        _ = df.string(from: viewModel.currentDate)
        ui.dateButton.setTitle(df.string(from: viewModel.currentDate), for: .normal)
    }
    func editTracker(_ trackerCoreData: TrackerCoreData) {
        guard let context = trackerCoreData.managedObjectContext else { return }
        guard let editVM = EditHabitViewModel(
                tracker: trackerCoreData,
                context: context,
                recordStore: viewModel.recordStore
            ) else { return }
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
            self.filtersViewModel.updateTracker(updatedTracker)

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.recalculateVisibleCategories()
                self.refreshCell(for: updatedTracker)
            }
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
            ui.calendarContainer.heightAnchor.constraint(equalToConstant: 320),
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
        viewModel.onSingleTrackerUpdated = { [weak self] updatedTracker, completed in
            guard let self = self else { return }
            AppLogger.trackers.info("[VC] Single tracker updated: \(updatedTracker.name)")
            self.filtersViewModel.updateTracker(updatedTracker)
            self.refreshCell(for: updatedTracker)
        }
        viewModel.onTrackersUpdated = { [weak self] in
            guard let self = self else { return }
            guard let updatedID = self.viewModel.lastUpdatedTrackerID else { return }
            let allVisibleTrackers = self.filtersViewModel.filteredTrackers
            guard let tracker = allVisibleTrackers.first(where: { $0.id == updatedID }) else { return }
            let categoryTitle = tracker.trackerCategory?.title ?? "Мои трекеры"
            guard let sectionIndex = self.visibleCategories.firstIndex(where: { $0.title == categoryTitle }) else { return }
            let trackersInSection = allVisibleTrackers.filter {
                $0.trackerCategory?.title == categoryTitle
            }
            guard let itemIndex = trackersInSection.firstIndex(where: { $0.id == updatedID }) else { return }
            let indexPath = IndexPath(item: itemIndex, section: sectionIndex)
            DispatchQueue.main.async {
                UIView.performWithoutAnimation {
                    self.ui.collectionView.reloadItems(at: [indexPath])
                }
            }
        }
        viewModel.onCategoriesUpdated = { [weak self] in
            guard let self = self else { return }
            self.scheduleUIRefresh()
        }
        viewModel.onDateChanged = { [weak self] date in
            guard let self = self else { return }
            self.filtersViewModel.selectedDate = date
            self.filtersViewModel.applyAllFilters(for: date)
            self.updateDateText()
            self.scheduleUIRefresh()
        }
        filtersViewModel.onFilteredTrackersUpdated = { [weak self] in
            guard let self = self else { return }
            self.scheduleUIRefresh()
        }
        filtersViewModel.onSingleTrackerUpdated = { [weak self] tracker, completed in
            guard let self else { return }
            if completed {
                self.viewModel.markTrackerAsCompleted(tracker, on: self.filtersViewModel.selectedDate)
            } else {
                self.viewModel.unmarkTrackerAsCompleted(tracker, on: self.filtersViewModel.selectedDate)
            }
        }
        viewModel.onSingleTrackerUpdated = { [weak self] updatedTracker, completed in
            self?.filtersViewModel.updateTracker(updatedTracker)
        }
    }
    private var uiUpdateWorkItem: DispatchWorkItem?
    private var lastUIReloadTime: Date?
    private func scheduleUIRefresh() {
        uiUpdateWorkItem?.cancel()
        let now = Date()
        if let last = lastUIReloadTime, now.timeIntervalSince(last) < 0.2 {
            return
        }
        lastUIReloadTime = now
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.recalculateVisibleCategories()
            self.ui.collectionView.reloadData()
            self.updatePlaceholder()
        }
        uiUpdateWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: work)
    }
    @objc private func addButtonTapped() {
        let createVC = CreateTrackerViewController()
        present(createVC, animated: true)
    }
    @objc private func toggleCalendar() {
        ui.calendarContainer.isHidden.toggle()
        if !ui.calendarContainer.isHidden {
            view.bringSubviewToFront(ui.calendarContainer)
        }
    }
    @objc private func calendarDateChanged(_ sender: UIDatePicker) {
        let newDate = sender.date
        ui.calendarContainer.isHidden = true
        viewModel.currentDate = newDate
        filtersViewModel.selectedDate = newDate
        ui.calendarView.setDate(newDate, animated: true)
        updateDateText()
        filtersViewModel.applyAllFilters(for: newDate)
        filtersViewModel.onFilteredTrackersUpdated?()
        recalculateVisibleCategories()
        ui.collectionView.reloadData()
        updatePlaceholder()
    }
    @objc private func filtersTapped() {
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
        viewModel.currentDate = today
        filtersViewModel.selectedDate = today
        ui.calendarView.setDate(today, animated: true)
        updateDateText()
        filtersViewModel.applyAllFilters(for: today)
        scheduleUIRefresh()
    }
    private func setupSearchBar() {
        ui.searchBar.delegate = self
    }
    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    @objc private func handleScreenTap(_: UITapGestureRecognizer) {
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
        if visibleCategories.isEmpty {
        } else {}
    }
    func setRecordStoreForTesting(_ store: TrackerRecordStore) {
        viewModel.recordStore = store
    }
    func refreshAllVisibleCellsForTesting() {
        ui.collectionView.visibleCells
            .compactMap { $0 as? TrackerCell }
            .forEach { $0.refreshCellState() }
    }
}
extension TrackersViewController {
    func reloadFromCoreData() {
        viewModel.onTrackersUpdated = { [weak self] in
            guard let self = self else { return }
            self.filtersViewModel.setInitialDataLoaded()
            self.filtersViewModel.applyAllFilters(for: self.viewModel.currentDate)
            self.recalculateVisibleCategories()
            self.ui.collectionView.reloadData()
            self.updatePlaceholder()
        }
        filtersViewModel.applyAllFilters(for: viewModel.currentDate)
        recalculateVisibleCategories()
        ui.collectionView.reloadData()
        viewModel.reloadTrackers()
    }
}
extension TrackersViewController {
    func updateUI() {
        scheduleUIRefresh()
        updatePlaceholder()
        updateDateText()
    }
}
extension TrackersViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let filtered = viewModel.searchTrackers(by: searchText)
        visibleCategories = viewModel.categories.filter { category in
            filtered.contains { $0.trackerCategory?.title == category.title }
        }
        ui.collectionView.reloadData()
        let hasTrackers = !filtered.isEmpty
        ui.placeholderView.isHidden = hasTrackers
        ui.collectionView.isHidden = !hasTrackers
        ui.filtersButton.isHidden = !hasTrackers
    }
}
