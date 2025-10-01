import UIKit

final class StatisticsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = NSLocalizedString("statistics.title", comment: "Заголовок страницы статистики")
    }
}
