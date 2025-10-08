import UIKit
import Combine

final class TrackersViewController: UIViewController {
    
    // MARK: - ViewModel
    let viewModel: TrackersViewModel
    
    // MARK: - UI Elements
    lazy var filtersButton: FiltersButton = {
        let button = FiltersButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(filtersTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var addButton: UIButton = {
        let button = UIButton(type: .system) // обязательно system!
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 42).isActive = true
        button.heightAnchor.constraint(equalToConstant: 42).isActive = true
        
        // Template Image из ассетов
        if let image = UIImage(named: "plus")?.withRenderingMode(.alwaysTemplate) {
            button.setImage(image, for: .normal)
        }
        
        // Динамический tintColor
        button.tintColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
            ? AppColors.textPrimary
            : AppColors.backgroundBlackButton
        }
        
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsets(top: 12, left: 11.5, bottom: 12, right: 11.5)
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var dateButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 77).isActive = true
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
        button.backgroundColor = AppColors.textSecondary.withAlphaComponent(0.1)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = AppFonts.caption2
        button.setTitleColor(AppColors.textPrimary, for: .normal)
        button.addTarget(self, action: #selector(toggleCalendar), for: .touchUpInside)
        return button
    }()
    
    let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = NSLocalizedString("trackers.search_placeholder", comment: "Placeholder для поиска трекеров")
        sb.searchBarStyle = .minimal
        sb.backgroundImage = UIImage()
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ in
            // Item
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5),
                                                  heightDimension: .absolute(140))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
            
            // Group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .estimated(150))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            // Section
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 16, trailing: 0)
            
            // Header
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                    heightDimension: .estimated(40))
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top)
            section.boundarySupplementaryItems = [sectionHeader]
            
            return section
        }
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = AppColors.background
        cv.delegate = self
        cv.dataSource = self
        cv.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.reuseIdentifier)
        cv.register(TrackerSectionHeaderView.self,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: TrackerSectionHeaderView.reuseIdentifier)
        return cv
    }()
    
    private let titleView = MainTitleLabelView(title: NSLocalizedString("trackers.title", comment: "Заголовок главного экрана трекеров"))
    private let placeholderView = PlaceholderView()
    
    
    
    // MARK: - Calendar Container
    lazy var calendarContainer: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = AppColors.background
        container.layer.cornerRadius = AppLayout.cornerRadius
        container.isHidden = true
        
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.1
        container.layer.shadowOffset = CGSize(width: 0, height: 4)
        container.layer.shadowRadius = 10
        
        container.addSubview(calendarView)
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            calendarView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            calendarView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            calendarView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        
        return container
    }()
    
    lazy var calendarView: UIDatePicker = {
        let dp = UIDatePicker()
        dp.backgroundColor = AppColors.background
        dp.overrideUserInterfaceStyle = traitCollection.userInterfaceStyle
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .inline
        dp.locale = Locale(identifier: "ru_RU")
        dp.calendar = Calendar(identifier: .gregorian)
        dp.addTarget(self, action: #selector(calendarDateChanged(_:)), for: .valueChanged)
        dp.translatesAutoresizingMaskIntoConstraints = false
        return dp
    }()
    
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
        
        // MARK: Register header
        collectionView.register(
            TrackerSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: TrackerSectionHeaderView.reuseIdentifier
        )
        print("🟢 Header registered for kind:", UICollectionView.elementKindSectionHeader)
        
        setupLayout()
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        collectionView.addGestureRecognizer(longPress)
        setupPlaceholder()
        placeholderView.configure(
            imageName: "Star",
            text: NSLocalizedString("trackers.placeholder_text", comment: "Текст при отсутствии трекеров")
        )
        
        setupCalendarContainer()
        bindViewModel()
        
        viewModel.ensureDefaultCategory()
        updatePlaceholder()
        updateDateText()
        
        searchBar.delegate = self
        searchBar.barTintColor = AppColors.background
        searchBar.searchTextField.backgroundColor = AppColors.background
        searchBar.searchTextField.textColor = AppColors.textPrimary
        searchBar.searchTextField.tintColor = AppColors.primaryBlue
        
        viewModel.trackerStore.debugPrintSchedules()
        
        view.addSubview(filtersButton)
        NSLayoutConstraint.activate([
            filtersButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filtersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            filtersButton.widthAnchor.constraint(equalToConstant: 114),
            filtersButton.heightAnchor.constraint(equalToConstant: 50)
        ])
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
        
        view.backgroundColor = AppColors.background
        collectionView.backgroundColor = AppColors.background
        
        searchBar.barTintColor = AppColors.background
        searchBar.searchTextField.backgroundColor = AppColors.background
        searchBar.searchTextField.textColor = AppColors.textPrimary
        
        dateButton.backgroundColor = AppColors.textSecondary.withAlphaComponent(0.1)
        dateButton.setTitleColor(AppColors.textPrimary, for: .normal)
        
        
        calendarContainer.backgroundColor = AppColors.background
        calendarView.backgroundColor = AppColors.background
    }
    
    // MARK: - Layout
    private func setupLayout() {
        MainHeaderLayoutHelper.setupTrackerLayout(
            in: view,
            titleView: titleView,
            addButton: addButton,
            dateButton: dateButton,
            searchBar: searchBar,
            collectionView: collectionView
        )
        
        // Добавляем остальные элементы
        view.addSubview(searchBar)
        view.addSubview(collectionView)
        
        // Отступы
        let spacingTitleToSearch: CGFloat = 2
        let spacingSearchToCollection: CGFloat = 8
        
        // Активируем констрейнты
        NSLayoutConstraint.activate([
            // Поиск под заголовком
            searchBar.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: spacingTitleToSearch),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Коллекция под поиском
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: spacingSearchToCollection),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func setupPlaceholder() {
        view.addSubview(placeholderView)
        NSLayoutConstraint.activate([
            placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func setupCalendarContainer() {
        view.addSubview(calendarContainer)
        NSLayoutConstraint.activate([
            calendarContainer.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 16),
            calendarContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            calendarContainer.widthAnchor.constraint(equalToConstant: 343),
            calendarContainer.heightAnchor.constraint(equalToConstant: 325)
        ])
    }
    
    func updatePlaceholder() {
        if viewModel.filteredTrackers.isEmpty {
            placeholderView.isHidden = false
            
            if let searchText = searchBar.text, !searchText.isEmpty {
                placeholderView.configure(
                    imageName: "NoSerach",
                    text: NSLocalizedString("trackers.placeholder_no_results", comment: "Текст при отсутствии результатов поиска")
                )
            } else {
                // Нет вообще трекеров
                placeholderView.configure(
                    imageName: "Star",
                    text: NSLocalizedString("trackers.placeholder_text", comment: "Текст при отсутствии трекеров")
                )
            }
        } else {
            placeholderView.isHidden = true
        }
    }
    
    func updateDateText() {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "dd.MM.yy"
        dateButton.setTitle(df.string(from: viewModel.currentDate), for: .normal)
    }
    
    // MARK: - Binding
    private func bindViewModel() {
        viewModel.onTrackersUpdated = { [weak self] in
            self?.collectionView.reloadData()
            self?.updatePlaceholder()
        }
        viewModel.onCategoriesUpdated = { [weak self] in
            self?.collectionView.reloadData()
        }
        viewModel.onDateChanged = { [weak self] date in
            self?.updateDateText()
            self?.collectionView.reloadData()
        }
        
        // Подписка на редактирование
        viewModel.onEditTracker = { [weak self] tracker in
            guard let self = self else { return }
            // Находим CoreData объект по id
            guard let trackerCoreData = self.viewModel.trackerStore.fetchTracker(by: tracker.id) else {
                print("❌ Не удалось найти TrackerCoreData для \(tracker.name)")
                return
            }
            self.editTracker(trackerCoreData)
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
        calendarContainer.isHidden.toggle()
    }
    
    @objc func calendarDateChanged(_ sender: UIDatePicker) {
        viewModel.currentDate = sender.date
        updateDateText()
        viewModel.filterByDate()
        collectionView.reloadData()
    }
    
    
    
    @objc private func filtersTapped() {
        AnalyticsService.shared.trackClick(item: "filter", screen: "Main")
        let filtersVC = FiltersViewController()
        filtersVC.onFilterSelected = { [weak self] index in
            guard let self = self else { return }
            self.viewModel.selectedFilterIndex = index
            self.collectionView.reloadData()
        }
        filtersVC.modalPresentationStyle = .pageSheet
        present(filtersVC, animated: true)
    }
}

// MARK: - Tracker Actions
private extension TrackersViewController {
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let location = gesture.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: location),
              let cell = collectionView.cellForItem(at: indexPath) else { return }
        
        guard nonEmptyCategories.indices.contains(indexPath.section) else { return }
        let category = nonEmptyCategories[indexPath.section]
        
        let trackersInCategory = viewModel.filteredTrackers.filter { tracker in
            tracker.trackerCategory?.title == category.title ||
            (tracker.trackerCategory == nil && category.title == "Мои трекеры")
        }
        
        guard trackersInCategory.indices.contains(indexPath.item) else { return }
        let tracker = trackersInCategory[indexPath.item]
        
        ActionMenuPresenter.show(for: cell, in: self, actions: [
            .init(title: (tracker.trackerCategory?.title == viewModel.pinnedCategoryTitle) ? "Открепить" : "Закрепить",
                  style: .default) { [weak self] in
                      guard let self = self else { return }
                      if tracker.trackerCategory?.title == self.viewModel.pinnedCategoryTitle {
                          self.viewModel.unpinTracker(tracker)
                      } else {
                          self.viewModel.pinTracker(tracker)
                      }
                  },
            .init(title: "Редактировать", style: .default) { [weak self] in
                guard let self = self else { return }
                AnalyticsService.shared.trackClick(item: "edit", screen: "Main")
                self.viewModel.editTracker(tracker)
            },
            .init(title: "Удалить", style: .destructive) { [weak self] in
                guard let self = self else { return }
                AnalyticsService.shared.trackClick(item: "delete", screen: "Main")
                let alert = UIAlertController(title: "Удалить трекер?", message: "Это действие нельзя отменить.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { _ in
                    self.viewModel.deleteTracker(tracker)
                })
                alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
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


extension TrackersViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Layout constants
    private enum Layout {
        static let itemWidth: CGFloat = 160
        static let itemHeight: CGFloat = 140
        static let lineSpacing: CGFloat = 16
        static let interitemSpacing: CGFloat = 25
        static let sectionInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        static let headerHeight: CGFloat = 30
    }
    
    // MARK: - Helper
    var nonEmptyCategories: [TrackerCategory] {
        viewModel.categories.filter { category in
            !viewModel.filteredTrackers.filter { $0.trackerCategory?.title == category.title || ($0.trackerCategory == nil && category.title == "Мои трекеры") }.isEmpty
        }
    }
    
    
    
    // MARK: - DataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let sections = nonEmptyCategories.isEmpty ? 1 : nonEmptyCategories.count
        print("🟢 numberOfSections: \(sections)")
        return sections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        updatePlaceholder()
        
        guard !nonEmptyCategories.isEmpty else {
            print("⚠️ No categories found, returning 0 items")
            return 0
        }
        
        let category = nonEmptyCategories[section]
        let trackersInCategory = viewModel.filteredTrackers.filter { tracker in
            tracker.trackerCategory?.title == category.title || (tracker.trackerCategory == nil && category.title == "Мои трекеры")
        }
        
        print("🟢 Section \(section) ('\(category.title)') has \(trackersInCategory.count) trackers")
        return trackersInCategory.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerCell.reuseIdentifier,
            for: indexPath
        ) as? TrackerCell else {
            print("❌ Failed to dequeue TrackerCell")
            return UICollectionViewCell()
        }
        
        guard nonEmptyCategories.indices.contains(indexPath.section) else {
            print("❌ section index out of range: \(indexPath.section)")
            return cell
        }
        
        let category = nonEmptyCategories[indexPath.section]
        
        let trackersInCategory = viewModel.filteredTrackers.filter { tracker in
            tracker.trackerCategory?.title == category.title ||
            (tracker.trackerCategory == nil && category.title == "Мои трекеры")
        }
        
        guard trackersInCategory.indices.contains(indexPath.item) else {
            print("❌ item index out of range: \(indexPath.item) / \(trackersInCategory.count)")
            return cell
        }
        
        let tracker = trackersInCategory[indexPath.item]
        
        let isCompleted = viewModel.isTrackerCompleted(tracker, on: viewModel.currentDate)
        let completedCount = viewModel.completedTrackers.filter { $0.trackerId == tracker.id }.count
        
        cell.configure(with: tracker, isCompleted: isCompleted, count: completedCount)
        
        let isFuture = Calendar.current.startOfDay(for: viewModel.currentDate) > Calendar.current.startOfDay(for: Date())
        cell.setCompletionEnabled(!isFuture)
        
        cell.onToggleCompletion = { [weak self, weak collectionView] in
            guard let self = self, let collectionView = collectionView else { return }
            if isFuture { return }
            
            // 🔹 Отправка события в AppMetrica
            AnalyticsService.shared.trackClick(item: "track", screen: "Main")
            
            if self.viewModel.isTrackerCompleted(tracker, on: self.viewModel.currentDate) {
                self.viewModel.unmarkTrackerAsCompleted(tracker, on: self.viewModel.currentDate)
            } else {
                self.viewModel.markTrackerAsCompleted(tracker, on: self.viewModel.currentDate)
            }
            
            collectionView.reloadItems(at: [indexPath])
        }
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        cell.addGestureRecognizer(longPressGesture)
        
        return cell
    }
    
    func addNewTracker(_ tracker: Tracker) {
        print("🟢 Adding new tracker: \(tracker.name)")
        viewModel.addTrackerToDefaultCategory(tracker)
    }
    
    func debugPrintTrackersSchedule() {
        print("🔍 Проверка расписания всех трекеров:")
        
        for tracker in viewModel.filteredTrackers {
            if !tracker.schedule.isEmpty {
                let days = tracker.schedule.map { $0.shortName }.joined(separator: ", ")
                print("🟢 \(tracker.name): \(days)")
            } else {
                print("⚠️ \(tracker.name): нет присвоенных дней недели")
            }
        }
    }
    
    // MARK: - Headers
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        
        guard kind == UICollectionView.elementKindSectionHeader else {
            print("⚪️ Unknown supplementary element kind: \(kind)")
            return UICollectionReusableView()
        }
        
        guard nonEmptyCategories.indices.contains(indexPath.section) else {
            print("⚠️ No category at section \(indexPath.section), returning empty header")
            let emptyHeader = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: TrackerSectionHeaderView.reuseIdentifier,
                for: indexPath
            ) as? TrackerSectionHeaderView
            emptyHeader?.configure(with: "")
            return emptyHeader ?? UICollectionReusableView()
        }
        
        let category = nonEmptyCategories[indexPath.section]
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: TrackerSectionHeaderView.reuseIdentifier,
            for: indexPath
        ) as! TrackerSectionHeaderView
        header.configure(with: category.title)
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard nonEmptyCategories.indices.contains(section) else {
            print("⚠️ No category at section \(section), header size = .zero")
            return .zero
        }
        
        let category = nonEmptyCategories[section]
        let trackersInCategory = viewModel.filteredTrackers.filter {
            $0.trackerCategory?.title == category.title || ($0.trackerCategory == nil && category.title == "Мои трекеры")
        }
        
        if trackersInCategory.isEmpty {
            print("⚠️ No trackers in category '\(category.title)', header size = .zero")
            return .zero
        }
        
        let size = CGSize(width: collectionView.bounds.width, height: Layout.headerHeight)
        print("🔵 Header size for section \(section): \(size)")
        return size
    }
    
    // MARK: - DelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = CGSize(width: Layout.itemWidth, height: Layout.itemHeight)
        print("📐 Cell size for \(indexPath): \(size)")
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Layout.lineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Layout.interitemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return Layout.sectionInsets
    }
}


