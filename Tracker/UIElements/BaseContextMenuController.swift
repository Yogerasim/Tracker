import UIKit

final class BaseContextMenuController<Cell: UIView>: NSObject, UIContextMenuInteractionDelegate {
    
    // MARK: - Properties
    private weak var owner: UIViewController?
    private weak var container: UIView?
    private let actionsProvider: (IndexPath) -> [UIAction]
    private let indexPathProvider: (Cell) -> IndexPath?
    
    // MARK: - Init
    init(
        owner: UIViewController,
        container: UIView,
        indexPathProvider: @escaping (Cell) -> IndexPath?,
        actionsProvider: @escaping (IndexPath) -> [UIAction]
    ) {
        self.owner = owner
        self.container = container
        self.indexPathProvider = indexPathProvider
        self.actionsProvider = actionsProvider
        super.init()
    }
    
    // MARK: - Public API
    func attach(to cell: Cell) {
        cell.interactions.forEach { cell.removeInteraction($0) }
        let interaction = UIContextMenuInteraction(delegate: self)
        cell.addInteraction(interaction)
    }
    
    // MARK: - UIContextMenuInteractionDelegate
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let cell = interaction.view as? Cell,
              let indexPath = indexPathProvider(cell)
        else { return nil }
        
        let actions = actionsProvider(indexPath)
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(title: "", children: actions)
        }
    }
    func addInteraction(to cell: UICollectionViewCell) {
        if cell.interactions.contains(where: { $0 is UIContextMenuInteraction }) { return }
        let interaction = UIContextMenuInteraction(delegate: self)
        cell.addInteraction(interaction)
    }
}
