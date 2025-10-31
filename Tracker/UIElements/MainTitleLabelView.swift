import UIKit
final class MainTitleLabelView: UIView {
    private let label: UILabel = {
        let label = UILabel()
        label.font = AppFonts.bigTitle
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white
                : AppColors.backgroundBlackButton
        }
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
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
    private func setupUI() {
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    func setTitle(_ text: String) {
        label.text = text
    }
}
