import UIKit

final class ModalHeaderView: UIView {

    // MARK: - UI
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.medium(16)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Init
    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout
    private func setupLayout() {
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            // Высота панели
            heightAnchor.constraint(equalToConstant: 90),

            // Заголовок по центру горизонтали и с отступом сверху 78
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
}
