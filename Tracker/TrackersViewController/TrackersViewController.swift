import UIKit

final class TrackersViewController: UIViewController {

    // MARK: - Stores
    private let categoryStore = TrackerCategoryStore()
    private let recordStore = TrackerRecordStore()

    // MARK: - State
    private let defaultCategoryTitle = "Мои трекеры"
    var currentDate: Date = Date() {
        didSet {
            print("📅 Выбрана новая дата: \(currentDate)")
            updateDateText()
            collectionView.reloadData()
            updatePlaceholder()
        }
    }
    
    // MARK: - Add New Tracker
    func addTrackerToDefaultCategory(_ tracker: Tracker) {
        categoryStore.addTracker(tracker, to: defaultCategoryTitle)
        print("📌 Трекер '\(tracker.name)' добавлен в категорию '\(defaultCategoryTitle)'")

        collectionView.reloadData()
        updatePlaceholder()
    }

    // MARK: - Computed Data
    var categories: [TrackerCategory] {
        categoryStore.categories
    }

    var completedTrackers: [TrackerRecord] {
        recordStore.completedTrackers
    }

    var trackers: [Tracker] {
        let day = weekDay(from: currentDate)
        return categories
            .flatMap { $0.trackers }
            .filter { $0.schedule.isEmpty || $0.schedule.contains(day) }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background

        navigationItem.leftBarButtonItem = addButtonItem
        navigationItem.title = ""

        setupLayout()
        setupPlaceholder()

        datePicker.date = currentDate
        updateDateText()

        ensureDefaultCategory()
        updatePlaceholder()

        print("✅ TrackersViewController загружен")
    }

    // MARK: - UI
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Трекеры"
        label.font = AppFonts.bigTitle
        label.textColor = AppColors.backgroundBlackButton
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Поиск"
        sb.backgroundImage = UIImage()
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()

    lazy var dateTextField: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .roundedRect
        tf.font = AppFonts.caption
        tf.textAlignment = .center
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.inputView = datePicker
        tf.tintColor = .clear
        tf.widthAnchor.constraint(equalToConstant: 110).isActive = true
        return tf
    }()

    lazy var titleStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, datePicker])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    lazy var datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        dp.preferredDatePickerStyle = .compact
        dp.locale = Locale(identifier: "ru_RU")
        dp.calendar = Calendar(identifier: .gregorian)
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
        label.textColor = AppColors.textSecondary
        label.font = AppFonts.caption
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

    // MARK: - Actions
    
    @objc func addButtonTapped() {
        let newHabitVC = NewHabitViewController()
        newHabitVC.onHabitCreated = { [weak self] tracker in
            guard let self = self else { return }
            print("🟢 TrackersViewController: получили новый трекер '\(tracker.name)' — добавляем в хранилище")
            self.categoryStore.addTracker(tracker, to: self.defaultCategoryTitle)
            self.collectionView.reloadData()
            self.updatePlaceholder()
        }
        present(newHabitVC, animated: true)
    }
    
    func ensureDefaultCategory() {
        if !categories.contains(where: { $0.title == defaultCategoryTitle }) {
            categoryStore.addCategory(
                TrackerCategory(title: defaultCategoryTitle, trackers: [])
            )
            print("📂 Создана категория по умолчанию '\(defaultCategoryTitle)'")
        }
    }

    func weekDay(from date: Date) -> WeekDay {
        let wd = Calendar.current.component(.weekday, from: date)
        let map = [6, 0, 1, 2, 3, 4, 5]
        return WeekDay(rawValue: map[wd - 1]) ?? .monday
    }

    func markTrackerAsCompleted(_ tracker: Tracker, on date: Date) {
        recordStore.addRecord(for: tracker.id, date: date)
        collectionView.reloadData()
    }

    func unmarkTrackerAsCompleted(_ tracker: Tracker, on date: Date) {
        recordStore.removeRecord(for: tracker.id, date: date)
        collectionView.reloadData()
    }

    func isTrackerCompleted(_ tracker: Tracker, on date: Date) -> Bool {
        recordStore.isCompleted(trackerId: tracker.id, date: date)
    }
}
