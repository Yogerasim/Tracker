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
            title: "Трекеры",
            image: UIImage(named: "Tracker"),
            selectedImage: UIImage(named: "Tracker")
        )
        
        let statisticsVC = UINavigationController(rootViewController: StatisticsViewController())
        statisticsVC.tabBarItem = UITabBarItem(
            title: "Статистика",
            image: UIImage(named: "Statistic"),
            selectedImage: UIImage(named: "Statistic")
        )
        
        viewControllers = [trackersVC, statisticsVC]
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // фон таббара
        appearance.backgroundColor = .white
        
        // разделительная линия (тень сверху)
        appearance.shadowColor = .gray
        
        // применяем для всех состояний
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }
}
