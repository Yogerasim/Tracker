import UIKit
import Combine

final class TrackersViewController: UIViewController {

    // MARK: - ViewModel
    let viewModel: TrackersViewModel
    let ui = TrackersUI()
    
    private let titleView = MainTitleLabelView(title: NSLocalizedString("trackers.title", comment: "Заголовок главного экрана трекеров"))
    private let placeholderView = PlaceholderView()
    
    var contextMenuController: BaseContextMenuController<TrackerCell>?

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

        registerCollectionViewCells()
        setupNavigationBarButtons()
        setupLayoutForRest()
        setupCalendarContainer()
        setupPlaceholder()
        setupBindings()
        setupContextMenuController()
        setupSearchBar()
        setupTapGesture()

        updateUI()
        updatePlaceholder()
        updateDateText()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsService.shared.trackOpen(screen: "Main")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AnalyticsService.shared.trackClose(screen: "Main")
    }

    // MARK: - Trait Changes
    private func updateColorsForCurrentTraitCollection() {
        view.backgroundColor = AppColors.background
        ui.collectionView.backgroundColor = AppColors.background
        ui.searchBar.barTintColor = AppColors.background
        ui.searchBar.searchTextField.backgroundColor = AppColors.background
        ui.searchBar.searchTextField.textColor = AppColors.textPrimary
        ui.dateButton.backgroundColor = AppColors.textSecondary.withAlphaComponent(0.1)
        ui.dateButton.setTitleColor(AppColors.textPrimary, for: .normal)
        ui.calendarContainer.backgroundColor = AppColors.background
        ui.calendarView.backgroundColor = AppColors.background
    }

    // MARK: - Setup CollectionView
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
        ui.collectionView.contentInset = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: view.safeAreaInsets.bottom + 50,
            right: 0
        )
    }

    // MARK: - Navigation Bar Buttons
    private func setupNavigationBarButtons() {
        ui.addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        ui.dateButton.addTarget(self, action: #selector(toggleCalendar), for: .touchUpInside)
        
        let container = UIView()
        container.addSubview(ui.addButton)
        container.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            ui.addButton.topAnchor.constraint(equalTo: container.topAnchor),
            ui.addButton.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ui.addButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            ui.addButton.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: container)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: ui.dateButton)
        navigationItem.titleView = nil
    }

    // MARK: - Layout
    private func setupLayoutForRest() {
        ui.filtersButton.addTarget(self, action: #selector(filtersTapped), for: .touchUpInside)
        [ui.titleView, ui.searchBar, ui.collectionView, ui.filtersButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            ui.titleView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            ui.titleView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            
            ui.searchBar.topAnchor.constraint(equalTo: ui.titleView.bottomAnchor, constant: 2),
            ui.searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            ui.searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            ui.collectionView.topAnchor.constraint(equalTo: ui.searchBar.bottomAnchor, constant: 8),
            ui.collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            ui.collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            ui.collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            ui.filtersButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ui.filtersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            ui.filtersButton.widthAnchor.constraint(equalToConstant: 114),
            ui.filtersButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Placeholder
    private func setupPlaceholder() {
        ui.placeholderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ui.placeholderView)
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

    func updatePlaceholder() {
        let hasTrackers = !viewModel.filteredTrackers.isEmpty
        ui.placeholderView.isHidden = hasTrackers
        ui.collectionView.isHidden = !hasTrackers
        ui.filtersButton.isHidden = !hasTrackers

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

    // MARK: - Calendar
    func setupCalendarContainer() {
        ui.calendarContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(ui.calendarContainer)
        
        NSLayoutConstraint.activate([
            ui.calendarContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            ui.calendarContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ui.calendarContainer.widthAnchor.constraint(equalToConstant: 365),
            ui.calendarContainer.heightAnchor.constraint(equalToConstant: 325)
        ])
        
        ui.calendarContainer.layer.shadowColor = UIColor.black.cgColor
        ui.calendarContainer.layer.shadowOpacity = 0.1
        ui.calendarContainer.layer.shadowOffset = CGSize(width: 0, height: 4)
        ui.calendarContainer.layer.shadowRadius = 8
        ui.calendarContainer.layer.masksToBounds = false
        
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

        ui.dateButton.setTitle(df.string(from: viewModel.currentDate), for: .normal)
    }

    // MARK: - Bindings
    private func setupBindings() {
        func scheduleUIRefresh(reason: String) {
            uiUpdateWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.recalculateVisibleCategories()
                guard self.ui.collectionView.window != nil else { return }
                self.ui.collectionView.reloadData()
                self.updatePlaceholder()
            }
            uiUpdateWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
        }

        let refreshUI: (String) -> Void = { reason in
            scheduleUIRefresh(reason: reason)
        }

        viewModel.onTrackersUpdated = { refreshUI("Trackers Updated") }
        viewModel.onCategoriesUpdated = { refreshUI("Categories Updated") }
        viewModel.onDateChanged = { _ in refreshUI("Date Changed") }

        viewModel.onEditTracker = { [weak self] tracker in
            guard let self else { return }
            guard let trackerCoreData = self.viewModel.trackerStore.fetchTracker(by: tracker.id) else { return }
            self.editTracker(trackerCoreData)
        }
    }

    private var uiUpdateWorkItem: DispatchWorkItem?
    
    // MARK: - Visible Categories
    var visibleCategories: [TrackerCategory] = []

    private func recalculateVisibleCategories() {
        visibleCategories = viewModel.categories.filter { category in
            viewModel.filteredTrackers.contains { tracker in
                (tracker.trackerCategory?.title ?? "Мои трекеры") == category.title
            }
        }
    }

    func updateUI() {
        recalculateVisibleCategories()
        DispatchQueue.main.async { [weak self] in
            guard let self, self.ui.collectionView.window != nil else { return }
            self.ui.collectionView.reloadData()
        }
    }

    // MARK: - Context Menu
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
                let trackersInCategory = self.viewModel.filteredTrackers.filter {
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

                let editAction = UIAction(title: NSLocalizedString("tracker.action.edit", comment: "Редактировать трекер"), image: UIImage(systemName: "pencil")) { _ in
                    self.viewModel.editTracker(tracker)
                }

                let deleteAction = UIAction(title: NSLocalizedString("tracker.action.delete", comment: "Удалить трекер"), image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                    self.deleteTracker(tracker)
                }

                return [pinAction, editAction, deleteAction]
            }
        )
    }

    // MARK: - Actions
    @objc func addButtonTapped() {
        let createVC = CreateTrackerViewController()
        createVC.onTrackerCreated = { [weak self] tracker in
            self?.viewModel.addTrackerToDefaultCategory(tracker)
        }
        present(createVC, animated: true)
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
    }

    @objc func filtersTapped() {
        let filtersVC = FiltersViewController()
        filtersVC.onFilterSelected = { [weak self] index in
            guard let self else { return }
            self.viewModel.selectedFilterIndex = index
            if index == 1 {
                let today = Date()
                self.viewModel.currentDate = today
                self.ui.calendarView.date = today
                self.updateDateText()
                self.viewModel.filterByDate()
            }
            self.ui.collectionView.reloadData()
        }
        filtersVC.modalPresentationStyle = .pageSheet
        present(filtersVC, animated: true)
    }

    func editTracker(_ tracker: TrackerCoreData) {
        guard let context = tracker.managedObjectContext else { return }
        guard let editVM = EditHabitViewModel(tracker: tracker, context: context) else { return }
        let editVC = EditHabitViewController(viewModel: editVM)
        present(editVC, animated: true)
    }

    func deleteTracker(_ tracker: Tracker) {
        let alert = UIAlertController(title: "Удалить трекер?", message: "Это действие нельзя отменить.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteTracker(tracker)
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func handleScreenTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: view)
        if ui.calendarContainer.frame.contains(location) { return }
        if !ui.calendarContainer.isHidden { ui.calendarContainer.isHidden = true }
    }

    // MARK: - Search
    private func setupSearchBar() {
        ui.searchBar.delegate = self
        ui.searchBar.barTintColor = AppColors.background
        ui.searchBar.searchTextField.backgroundColor = AppColors.background
        ui.searchBar.searchTextField.textColor = AppColors.textPrimary
        ui.searchBar.searchTextField.tintColor = AppColors.primaryBlue
    }

    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap(_:)))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
}

// MARK: - UISearchBarDelegate
extension TrackersViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchText = searchText
        updatePlaceholder()
    }
}
