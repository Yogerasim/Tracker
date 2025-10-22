import UIKit

final class StatisticsViewController: UIViewController {
    
    // MARK: - Dependencies
    private let trackerRecordStore: TrackerRecordStore
    private let placeholderView = PlaceholderView()
    
    // MARK: - Init
    init(trackerRecordStore: TrackerRecordStore) {
        self.trackerRecordStore = trackerRecordStore
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
    
    // MARK: - UI Elements
    private let titleView = MainTitleLabelView(
        title: NSLocalizedString("statistics.title", comment: "Заголовок страницы статистики")
    )
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.isScrollEnabled = false
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        return table
    }()
    
    // MARK: - Layout Constraints
    private var titleTopConstraint: NSLayoutConstraint!
    private var tableViewCenterYConstraint: NSLayoutConstraint!
    private var tableViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Data
    private var items: [(Int, String)] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("📊 [StatsVC] viewDidLoad called")
        
        view.backgroundColor = AppColors.background
        setupLayout()
        setupTableView()
        
        print("📊 [StatsVC] before loadStatistics()")
        loadStatistics()
        print("📊 [StatsVC] after loadStatistics(), items.count = \(items.count)")
        
        updatePlaceholderVisibility()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTrackerRecordsDidChange),
            name: .trackerRecordsDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTrackerRecordsDidChange),
            name: .trackersDidChange,
            object: nil
        )
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("📊 [StatsVC] viewWillAppear — refreshing stats")
        loadStatistics()
    }
    
    // MARK: - Load Data
    private func loadStatistics() {
        print("📊 [StatsVC] loadStatistics() called")
        let calculator = CalculateStatistics(trackerRecordStore: trackerRecordStore)
        let stats = calculator.calculateStatistics()
        
        items = [
            (stats.bestPeriod, NSLocalizedString("statistics.best_period_label", comment: "Лучший период")),
            (stats.idealDays, NSLocalizedString("statistics.ideal_days_label", comment: "Идеальные дни")),
            (stats.completedTrackers, NSLocalizedString("statistics.completed_trackers_label", comment: "Трекеров завершено")),
            (stats.averageTrackersPerDay, NSLocalizedString("statistics.average_label", comment: "Среднее значение"))
        ]
        print("📊 [StatsVC] stats = \(stats)")
        
        tableView.reloadData()
        updateTableHeight()
        updatePlaceholderVisibility()
    }
    
    // MARK: - Placeholder Logic
    private func updatePlaceholderVisibility() {
        print("📊 [StatsVC] updatePlaceholderVisibility() called")
        
        let trackerStore = TrackerStore(context: trackerRecordStore.context)
        let trackers = trackerStore.getTrackers()
        print("📊 [StatsVC] getTrackers count = \(trackers.count)")
        
        let hasCreatedTrackers = !trackers.isEmpty
        print("📊 [StatsVC] hasCreatedTrackers = \(hasCreatedTrackers)")
        
        placeholderView.isHidden = hasCreatedTrackers
        tableView.isHidden = !hasCreatedTrackers
        
        if !hasCreatedTrackers {
            print("📊 [StatsVC] showing placeholder (нет трекеров)")
            placeholderView.configure(
                imageName: "NoStatistic",
                text: NSLocalizedString("statistics.placeholder.empty", comment: "Пустая статистика — нечего анализировать")
            )
        } else {
            print("📊 [StatsVC] showing tableView (есть трекеры)")
        }
    }
    
    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(titleView)
        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleTopConstraint = titleView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44)
        NSLayoutConstraint.activate([
            titleTopConstraint,
            titleView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25)
        ])
        
        view.addSubview(tableView)
        view.addSubview(placeholderView)
        tableViewCenterYConstraint = tableView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            titleView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            titleView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            
            tableViewCenterYConstraint,
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableViewHeightConstraint,
            
            placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            placeholderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            placeholderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        placeholderView.isHidden = true
    }
    
    private func updateTableHeight() {
        let totalHeight = CGFloat(items.count * 90 + (items.count - 1) * 16)
        print("📊 [StatsVC] updateTableHeight() totalHeight = \(totalHeight)")
        tableViewHeightConstraint.constant = totalHeight
    }
    
    private func setupTableView() {
        tableView.register(StatisticsTableViewCell.self, forCellReuseIdentifier: "StatisticsCell")
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    @objc private func handleTrackerRecordsDidChange() {
        print("📊 [StatsVC] received .trackerRecordsDidChange — reloading stats")
        loadStatistics()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Title Manipulation
    func moveTitle(upBy offset: CGFloat) {
        titleTopConstraint.constant = 44 - offset
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - UITableViewDataSource
extension StatisticsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "StatisticsCell", for: indexPath) as? StatisticsTableViewCell else {
            return UITableViewCell()
        }
        let item = items[indexPath.section]
        cell.configure(title: item.0, subtitle: item.1)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension StatisticsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 16
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
}
