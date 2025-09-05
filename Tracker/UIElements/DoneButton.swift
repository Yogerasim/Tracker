import UIKit

final class DoneButton: UIButton {
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyle()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStyle()
    }
    
    // MARK: - Setup
    private func setupStyle() {
        setTitle("Готово", for: .normal)
        setTitleColor(AppColors.textPrimary, for: .normal)
        backgroundColor = AppColors.backgroundBlackButton
        titleLabel?.font = AppFonts.body
        layer.cornerRadius = AppLayout.cornerRadius
        translatesAutoresizingMaskIntoConstraints = false
    }
}
