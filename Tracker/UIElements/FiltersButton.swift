import UIKit

final class FiltersButton: UIButton {
    
    // MARK: - Init
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {

        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = AppColors.darkBlue
        layer.cornerRadius = 16
        clipsToBounds = true

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 114),
            heightAnchor.constraint(equalToConstant: 50)
        ])
        
        setTitle(
            NSLocalizedString("filters.button_title", comment: "Фильтры"),
            for: .normal
        )
        setTitleColor(.white, for: .normal)
        titleLabel?.font = AppFonts.regular(17)
    }
}
