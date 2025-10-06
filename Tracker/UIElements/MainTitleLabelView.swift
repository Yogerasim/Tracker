import UIKit

final class MainTitleLabelView: UIView {
    
    // MARK: - UI
    private let label: UILabel = {
        let label = UILabel()
        label.font = AppFonts.bigTitle
        label.textColor = AppColors.backgroundBlackButton
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Init
    init(title: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupUI()
        setTitle(title)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Private methods
    private func setupUI() {
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Public methods
    func setTitle(_ text: String) {
        label.text = text
    }
}
