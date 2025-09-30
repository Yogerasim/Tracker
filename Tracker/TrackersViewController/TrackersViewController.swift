import UIKit

final class TrackersViewController: UIViewController {
    
    // MARK: - Stores
    private let categoryStore: TrackerCategoryStore
    private let recordStore: TrackerRecordStore
    private let trackerStore: TrackerStore
    
    // MARK: - State
    private let defaultCategoryTitle = "Мои трекеры"
    private(set) var trackers: [Tracker] = []
    private var isDatePickerVisible = false
    
    var currentDate: Date = Date() {
        didSet {
            print("📅 Выбрана новая дата: \(currentDate)")
            updateDateText()
            collectionView.reloadData()
            updatePlaceholder()
        }
    }
    
    // MARK: - Init
    init() {
        let container = CoreDataStack.shared.persistentContainer
        self.categoryStore = TrackerCategoryStore(context: container.viewContext)
        self.recordStore = TrackerRecordStore(persistentContainer: container)
        self.trackerStore = TrackerStore(context: container.viewContext)
        super.init(nibName: nil, bundle: nil)
        self.trackerStore.delegate = self
    }

    required init?(coder: NSCoder) {
        let container = CoreDataStack.shared.persistentContainer
        self.categoryStore = TrackerCategoryStore(context: container.viewContext)
        self.recordStore = TrackerRecordStore(persistentContainer: container)
        self.trackerStore = TrackerStore(context: container.viewContext)
        super.init(coder: coder)
        self.trackerStore.delegate = self
    }
    
    // MARK: - Add New Tracker
    func addTrackerToDefaultCategory(_ tracker: Tracker) {
        categoryStore.addTracker(tracker, to: defaultCategoryTitle)
        trackerStore.add(tracker)
        
        updateCurrentDateForNewTracker(tracker)
        print("📌 Трекер '\(tracker.name)' добавлен в категорию '\(defaultCategoryTitle)'")
    }
    
    // MARK: - Update currentDate for new tracker
    private func updateCurrentDateForNewTracker(_ tracker: Tracker) {
        guard !tracker.schedule.isEmpty else { return }
        
        let todayWeekday = Calendar.current.component(.weekday, from: Date())
        let weekdaysMap: [Int: WeekDay] = [
            1: .sunday, 2: .monday, 3: .tuesday, 4: .wednesday,
            5: .thursday, 6: .friday, 7: .saturday
        ]
        
        let sortedDays = tracker.schedule.sorted { $0.rawValue < $1.rawValue }
        
        for offset in 0..<7 {
            let nextDayIndex = (todayWeekday + offset - 1) % 7 + 1
            if let day = weekdaysMap[nextDayIndex], sortedDays.contains(day),
               let nextDate = Calendar.current.date(byAdding: .day, value: offset, to: Date()) {
                currentDate = nextDate
                break
            }
        }
    }
    
    // MARK: - Computed Data
    var categories: [TrackerCategory] {
        categoryStore.categories
    }
    
    var completedTrackers: [TrackerRecord] {
        recordStore.completedTrackers
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        
        navigationItem.leftBarButtonItem = addButtonItem
        navigationItem.title = ""
        
        setupLayout()
        setupPlaceholder()
        
        ensureDefaultCategory()
        updatePlaceholder()
        
        categoryStore.delegate = self
        
        collectionView.reloadData()
        
        datePicker.date = currentDate
        updateDateText()
        
        view.addSubview(datePickerContainer)
        datePickerContainer.addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            datePickerContainer.topAnchor.constraint(equalTo: titleStack.bottomAnchor, constant: 8),
            datePickerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            datePickerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // сам datePicker внутри контейнера
            datePicker.topAnchor.constraint(equalTo: datePickerContainer.topAnchor, constant: 8),
            datePicker.leadingAnchor.constraint(equalTo: datePickerContainer.leadingAnchor, constant: 8),
            datePicker.trailingAnchor.constraint(equalTo: datePickerContainer.trailingAnchor, constant: -8),
            datePicker.bottomAnchor.constraint(equalTo: datePickerContainer.bottomAnchor, constant: -8)
        ])
        
        print("✅ TrackersViewController загружен")
    }
    
    // MARK: - UI Elements для Date.swift и Layout.swift
    lazy var dateTextField: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.font = AppFonts.caption
        tf.textAlignment = .center
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.tintColor = .clear

        // Тап по полю — показывает/скрывает datePicker
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleDatePicker))
        tf.addGestureRecognizer(tapGesture)

        return tf
    }()
    
    lazy var titleStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, dateTextField])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Поиск"
        sb.searchBarStyle = .minimal
        sb.backgroundImage = UIImage()
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()
    
    // MARK: - UI
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Трекеры"
        label.font = AppFonts.bigTitle
        label.textColor = AppColors.backgroundBlackButton
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var datePicker: UIDatePicker = {
            let dp = UIDatePicker()
            dp.datePickerMode = .date
            dp.preferredDatePickerStyle = .inline
            dp.locale = Locale(identifier: "ru_RU")
            dp.calendar = Calendar(identifier: .gregorian)
            dp.translatesAutoresizingMaskIntoConstraints = false
            dp.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
            
            return dp
        }()
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 160, height: 140)
        layout.minimumLineSpacing = AppLayout.padding
        layout.minimumInteritemSpacing = 8
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.reuseIdentifier)
        return cv
    }()
    
    let placeholderView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: UIImage(named: "Star"))
        imageView.tintColor = AppColors.textSecondary
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.textColor = AppColors.backgroundBlackButton
        label.font = AppFonts.plug
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(imageView)
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),
            
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }()
    
    private lazy var addButtonItem: UIBarButtonItem = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "plus"), for: .normal)
        button.tintColor = AppColors.backgroundBlackButton
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        
        button.widthAnchor.constraint(equalToConstant: 24).isActive = true
        button.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
        return UIBarButtonItem(customView: button)
    }()
    
    private lazy var datePickerContainer: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .systemBackground // системный белый фон
        container.layer.cornerRadius = 12
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.1
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 4
        container.isHidden = true
        return container
    }()
    
    // MARK: - Actions
    @objc func addButtonTapped() {
        let createTrackerVC = CreateTrackerViewController()

        createTrackerVC.onTrackerCreated = { [weak self] tracker in
            self?.addTrackerToDefaultCategory(tracker)
        }

        present(createTrackerVC, animated: true)
    }

    @objc func toggleDatePicker() {
        isDatePickerVisible.toggle()
        UIView.animate(withDuration: 0.25) {
            self.datePickerContainer.isHidden = !self.isDatePickerVisible
        }
    }

    @objc private func dateChanged(_ sender: UIDatePicker) {
        currentDate = sender.date
    }
    
    func ensureDefaultCategory() {
        if !categories.contains(where: { $0.title == defaultCategoryTitle }) {
            categoryStore.add(
                TrackerCategory(id: UUID(), title: defaultCategoryTitle, trackers: [])
            )
            print("📂 Создана категория по умолчанию '\(defaultCategoryTitle)'")
        }
    }
    
    func markTrackerAsCompleted(_ tracker: Tracker, on date: Date) {
        let today = Calendar.current.startOfDay(for: Date())
        let selectedDay = Calendar.current.startOfDay(for: date)
        
        guard selectedDay <= today else {
            print("⚠️ Нельзя отмечать трекеры в будущем: \(selectedDay)")
            return
        }
        
        if let trackerCoreData = recordStore.fetchTracker(by: tracker.id) {
            recordStore.addRecord(for: trackerCoreData, date: date)
            collectionView.reloadData()
        } else {
            print("⚠️ Не найден TrackerCoreData для id: \(tracker.id)")
        }
    }
    
    func unmarkTrackerAsCompleted(_ tracker: Tracker, on date: Date) {
        if let trackerCoreData = recordStore.fetchTracker(by: tracker.id) {
            recordStore.removeRecord(for: trackerCoreData, date: date)
            collectionView.reloadData()
        }
    }
    
    func isTrackerCompleted(_ tracker: Tracker, on date: Date) -> Bool {
        guard let trackerCoreData = recordStore.fetchTracker(by: tracker.id) else {
            return false
        }
        return recordStore.isCompleted(for: trackerCoreData, date: date)
    }
    
}

// MARK: - TrackerStoreDelegate
extension TrackersViewController: TrackerStoreDelegate {
    func didUpdateTrackers(_ trackers: [Tracker]) {
        print("🔄 Обновлено \(trackers.count) трекеров из Core Data")
        self.trackers = trackers
        collectionView.reloadData()
        updatePlaceholder()
    }
}

// MARK: - TrackerCategoryStoreDelegate
extension TrackersViewController: TrackerCategoryStoreDelegate {
    func didUpdateCategories() {
        collectionView.reloadData()
    }
}
