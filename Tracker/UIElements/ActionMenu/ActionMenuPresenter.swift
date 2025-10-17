import UIKit

final class ActionMenuPresenter {
    struct MenuAction {
        let title: String
        let style: UIAlertAction.Style
        let handler: (() -> Void)?
    }

    static func show(
        for sourceView: UIView,
        in parentVC: UIViewController,
        actions: [MenuAction]
    ) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        for action in actions {
            alert.addAction(UIAlertAction(title: action.title, style: action.style) { _ in
                action.handler?()
            })
        }

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = CGRect(
                x: sourceView.bounds.maxX - 10,
                y: sourceView.bounds.midY,
                width: 1, height: 1
            )
            popover.permittedArrowDirections = [.right]
        }

        parentVC.present(alert, animated: true)
    }
}
