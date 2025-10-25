import UIKit

final class ModalHeaderView: UIView {
    
    // MARK: - UI
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.medium(16)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.9)
            : AppColors.backgroundBlackButton
        }
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Init
    init(title: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false 
        backgroundColor = AppColors.background
        titleLabel.text = title
        setupLayout()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
    
    // MARK: - Public API
    func setTitle(_ title: String) {
        titleLabel.text = title
    }
    
    // MARK: - Layout
    private func setupLayout() {
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 90),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
}
