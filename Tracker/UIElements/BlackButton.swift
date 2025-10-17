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
        
        // Фон кнопки: белый в темной теме, чёрный/цвет кнопки в светлой
        backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
            ? UIColor.white
            : AppColors.backgroundBlackButton
        }
        
        
        setTitleColor(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
            ? AppColors.backgroundBlackButton   
            : UIColor.white
        }, for: .normal)
        
        layer.cornerRadius = AppLayout.cornerRadius
        titleLabel?.font = AppFonts.subheadline
        translatesAutoresizingMaskIntoConstraints = false
    }
}

