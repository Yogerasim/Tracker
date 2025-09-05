import UIKit

final class BlackButton: UIButton {

    // MARK: - Init
    init(title: String) {
        super.init(frame: .zero)
        setupUI(title: title)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupUI(title: String) {
        setTitle(title, for: .normal)
        backgroundColor = AppColors.backgroundBlackButton
        setTitleColor(AppColors.textPrimary, for: .normal)
        layer.cornerRadius = AppLayout.cornerRadius
        titleLabel?.font = AppFonts.subheadline
        translatesAutoresizingMaskIntoConstraints = false
    }
}

