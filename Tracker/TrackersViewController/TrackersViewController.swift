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
        
        // Цвет фона
        view.backgroundColor = AppColors.background
        
        // Регистрация header для коллекции
        ui.collectionView.register(
            TrackerSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: TrackerSectionHeaderView.reuseIdentifier
        )
        
        // Настройка layout через ui
        setupLayout()
        
        // Добавляем распознавание долгого нажатия на ячейки
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        ui.collectionView.addGestureRecognizer(longPress)
        
        // Настройка placeholder
        ui.placeholderView.configure(
            imageName: "Star",
            text: NSLocalizedString("trackers.placeholder_text", comment: "Текст при отсутствии трекеров")
        )
        
        // Настройка календаря
        setupCalendarContainer()
        
        // Привязка ViewModel
        bindViewModel()
        
        // Убедимся, что есть дефолтная категория
        viewModel.ensureDefaultCategory()
        
        // Обновление placeholder и даты
        updatePlaceholder()
        updateDateText()
        
        // Настройка searchBar
        ui.searchBar.delegate = self
        ui.searchBar.barTintColor = AppColors.background
        ui.searchBar.searchTextField.backgroundColor = AppColors.background
        ui.searchBar.searchTextField.textColor = AppColors.textPrimary
        ui.searchBar.searchTextField.tintColor = AppColors.primaryBlue
        
        // Отладка расписания трекеров
        viewModel.trackerStore.debugPrintSchedules()
        
        // Привязываем действия к кнопкам
        ui.addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        ui.dateButton.addTarget(self, action: #selector(toggleCalendar), for: .touchUpInside)
        ui.filtersButton.addTarget(self, action: #selector(filtersTapped), for: .touchUpInside)
        ui.calendarView.addTarget(self, action: #selector(calendarDateChanged(_:)), for: .valueChanged)
        ui.collectionView.dataSource = self
        ui.collectionView.delegate = self
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
    private func setupLayout() {
        // Настраиваем основной layout через хелпер, передавая элементы из ui
        MainHeaderLayoutHelper.setupTrackerLayout(
            in: view,
            titleView: ui.titleView,
            addButton: ui.addButton,
            dateButton: ui.dateButton,
            searchBar: ui.searchBar,
            collectionView: ui.collectionView
        )
        
        view.addSubview(ui.filtersButton)
        NSLayoutConstraint.activate([
            ui.filtersButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ui.filtersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            ui.filtersButton.widthAnchor.constraint(equalToConstant: 114),
            ui.filtersButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Отступы между поиском и коллекцией
        let spacingTitleToSearch: CGFloat = 2
        let spacingSearchToCollection: CGFloat = 8
        
        // Активируем констрейнты для поиска и коллекции
        NSLayoutConstraint.activate([
            // Поиск под заголовком
            ui.searchBar.topAnchor.constraint(equalTo: ui.titleView.bottomAnchor, constant: spacingTitleToSearch),
            ui.searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            ui.searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Коллекция под поиском
            ui.collectionView.topAnchor.constraint(equalTo: ui.searchBar.bottomAnchor, constant: spacingSearchToCollection),
            ui.collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            ui.collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            ui.collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
        view.addSubview(ui.calendarContainer)
        NSLayoutConstraint.activate([
            ui.calendarContainer.topAnchor.constraint(equalTo: ui.addButton.bottomAnchor, constant: 16),
            ui.calendarContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ui.calendarContainer.widthAnchor.constraint(equalToConstant: 343),
            ui.calendarContainer.heightAnchor.constraint(equalToConstant: 325)
        ])
    }
    
    func updatePlaceholder() {
        if viewModel.filteredTrackers.isEmpty {
            ui.placeholderView.isHidden = false
            
            if let searchText = ui.searchBar.text, !searchText.isEmpty {
                ui.placeholderView.configure(
                    imageName: "NoSerach",
                    text: NSLocalizedString("trackers.placeholder_no_results", comment: "Текст при отсутствии результатов поиска")
                )
            } else {
                // Нет вообще трекеров
                ui.placeholderView.configure(
                    imageName: "Star",
                    text: NSLocalizedString("trackers.placeholder_text", comment: "Текст при отсутствии трекеров")
                )
            }
        } else {
            ui.placeholderView.isHidden = true
        }
    }
    
    func updateDateText() {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "dd.MM.yy"
        ui.dateButton.setTitle(df.string(from: viewModel.currentDate), for: .normal)
    }
    
    // MARK: - Binding
    private func bindViewModel() {
        viewModel.onTrackersUpdated = { [weak self] in
            self?.ui.collectionView.reloadData()
            self?.updatePlaceholder()
        }
        
        viewModel.onCategoriesUpdated = { [weak self] in
            self?.ui.collectionView.reloadData()
        }
        
        viewModel.onDateChanged = { [weak self] date in
            self?.updateDateText()
            self?.ui.collectionView.reloadData()
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
        ui.calendarContainer.isHidden.toggle()
    }
    
    @objc func calendarDateChanged(_ sender: UIDatePicker) {
        viewModel.currentDate = sender.date
        updateDateText()
        viewModel.filterByDate()
        ui.collectionView.reloadData()
    }
    
    @objc private func filtersTapped() {
        AnalyticsService.shared.trackClick(item: "filter", screen: "Main")
        let filtersVC = FiltersViewController()
        filtersVC.onFilterSelected = { [weak self] index in
            guard let self = self else { return }
            self.viewModel.selectedFilterIndex = index
            self.ui.collectionView.reloadData()
        }
        filtersVC.modalPresentationStyle = .pageSheet
        present(filtersVC, animated: true)
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let location = gesture.location(in: ui.collectionView)
        guard let indexPath = ui.collectionView.indexPathForItem(at: location),
              let cell = ui.collectionView.cellForItem(at: indexPath) else { return }
        
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


