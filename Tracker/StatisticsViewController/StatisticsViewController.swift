import UIKit

final class StatisticsViewController: UIViewController {

    // MARK: - Dependencies
    private let trackerRecordStore: TrackerRecordStore

    // MARK: - Init
    init(trackerRecordStore: TrackerRecordStore) {
        self.trackerRecordStore = trackerRecordStore
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        return table
    }()

    // MARK: - Data
    private var items: [(Int, String)] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        setupLayout()
        setupTableView()
        loadStatistics()
    }

    // MARK: - Load Data
    private func loadStatistics() {
        let stats = trackerRecordStore.calculateStatistics()
        items = [
            (stats.bestPeriod, NSLocalizedString("statistics.best_period_label", comment: "Лучший период")),
            (stats.idealDays, NSLocalizedString("statistics.ideal_days_label", comment: "Идеальные дни")),
            (stats.completedTrackers, NSLocalizedString("statistics.completed_trackers_label", comment: "Трекеров завершено")),
            (stats.averageTrackersPerDay, NSLocalizedString("statistics.average_label", comment: "Среднее значение"))
        ]
        tableView.reloadData()
    }

    // MARK: - Layout
    private func setupLayout() {
        MainHeaderLayoutHelper.setupSimpleTitle(in: view, titleView: titleView)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: titleView.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupTableView() {
        tableView.register(StatisticsTableViewCell.self, forCellReuseIdentifier: "StatisticsCell")
        tableView.dataSource = self
        tableView.delegate = self
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
