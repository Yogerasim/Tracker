import UIKit

final class DoneButton: UIButton {

    override var isEnabled: Bool {
        didSet { updateStyle() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyle()
        updateStyle()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStyle()
        updateStyle()
    }

    private func setupStyle() {
        setTitle(NSLocalizedString("done_button", comment: "Готово"), for: .normal)
        titleLabel?.font = AppFonts.body
        layer.cornerRadius = AppLayout.cornerRadius
        translatesAutoresizingMaskIntoConstraints = false

        // Базовые динамические цвета — как в createButton
        backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? UIColor.white
            : AppColors.backgroundBlackButton
        }

        setTitleColor(UIColor { trait in
            trait.userInterfaceStyle == .dark
            ? AppColors.backgroundBlackButton
            : UIColor.white
        }, for: .normal)
    }

    private func updateStyle() {
        alpha = isEnabled ? 1.0 : 0.5
    }
}
