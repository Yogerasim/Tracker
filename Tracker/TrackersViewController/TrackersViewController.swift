import UIKit
import Combine

final class TrackersViewController: UIViewController {
    
    // MARK: - ViewModel
    let viewModel: TrackersViewModel
    
    // MARK: - UI Elements
    lazy var addButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 42).isActive = true
        button.heightAnchor.constraint(equalToConstant: 42).isActive = true
        let image = UIImage(named: "plus")?.withRenderingMode(.alwaysOriginal)
        button.setImage(image, for: .normal)
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
        button.setTitleColor(AppColors.backgroundBlackButton, for: .normal)
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
        
        setupLayout()
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
    }
    
    // MARK: - Actions
    @objc func addButtonTapped() {
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
        collectionView.reloadData()
    }
}

extension TrackersViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchText = searchText
        updatePlaceholder()
    }
}
