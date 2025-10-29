import UIKit

final class PlaceholderView: UIView {
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = AppColors.textSecondary
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let label: UILabel = {
        let lbl = UILabel()
        lbl.font = AppFonts.plug
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        lbl.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: 0.9)
                : AppColors.backgroundBlackButton
        }
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    func configure(imageName: String?, text: String) {
        if let imageName = imageName {
            imageView.image = UIImage(named: imageName)
        } else {
            imageView.image = nil
        }
        label.text = text
    }

    private func setupLayout() {
        addSubview(imageView)
        addSubview(label)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
