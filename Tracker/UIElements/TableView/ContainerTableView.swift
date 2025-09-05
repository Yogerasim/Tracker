import UIKit

final class ContainerTableView: UIView {

    private var heightConstraint: NSLayoutConstraint?

    let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.isScrollEnabled = false
        table.separatorStyle = .none
        table.backgroundColor = .systemGray6
        table.translatesAutoresizingMaskIntoConstraints = false
        table.rowHeight = 75 // фиксированная высота строки
        return table
    }()

    init(backgroundColor: UIColor = .systemGray6, cornerRadius: CGFloat = AppLayout.cornerRadius) {
        super.init(frame: .zero)
        self.backgroundColor = backgroundColor
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = true
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    
    func updateHeight(forRows count: Int) {
        let newHeight = CGFloat(count) * tableView.rowHeight
        if let heightConstraint = heightConstraint {
            heightConstraint.constant = newHeight
        } else {
            heightConstraint = heightAnchor.constraint(equalToConstant: newHeight)
            heightConstraint?.isActive = true
        }
        layoutIfNeeded()
    }
}
