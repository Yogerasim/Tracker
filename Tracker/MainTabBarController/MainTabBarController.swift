import UIKit

// MARK: - MainTabBarController
final class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewControllers()
        configureTabBarAppearance()
    }
    
    private func configureViewControllers() {
        let trackersVC = UINavigationController(rootViewController: TrackersViewController())
        trackersVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("tab_trackers", comment: "Название вкладки для списка трекеров"),
            image: UIImage(named: "Tracker"),
            selectedImage: UIImage(named: "Tracker")
        )
        
        let trackerRecordStore = TrackerRecordStore(persistentContainer: CoreDataStack.shared.persistentContainer)
        let statisticsVC = UINavigationController(rootViewController: StatisticsViewController(trackerRecordStore: trackerRecordStore))
        statisticsVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("tab_statistics", comment: "Название вкладки для статистики"),
            image: UIImage(named: "Statistic"),
            selectedImage: UIImage(named: "Statistic")
        )
        
        viewControllers = [trackersVC, statisticsVC]
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Фон таббара с поддержкой dark mode
        appearance.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? AppColors.backgroundBlackButton
                : .white
        }
        
        // Разделительная линия (тень сверху) с поддержкой dark mode
        appearance.shadowColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: 0.1)
                : UIColor.gray
        }
        
        // Применяем для всех состояний
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }
}
