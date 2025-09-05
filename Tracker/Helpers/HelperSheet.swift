import UIKit

extension UIViewController {
    /// Открывает контроллер модально в стиле "page sheet" на полный экран
    func presentFullScreenSheet(_ viewController: UIViewController) {
        viewController.modalPresentationStyle = .pageSheet
        if let sheet = viewController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(viewController, animated: true)
    }
}
