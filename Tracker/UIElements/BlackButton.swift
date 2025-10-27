import UIKit

final class BlackButton: UIButton {
    
    
    init(title: String) {
        super.init(frame: .zero)
        setupUI(title: title)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
    
    
    private func setupUI(title: String) {
        setTitle(title, for: .normal)
        
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

