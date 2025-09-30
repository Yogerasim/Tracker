import UIKit

// MARK: - PlaceholderView
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
        lbl.textColor = AppColors.backgroundBlackButton
        lbl.font = AppFonts.plug
        lbl.textAlignment = .center
        lbl.numberOfLines = 0 // разрешаем перенос текста
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(image: UIImage? = UIImage(named: "Star"), text: String) {
        imageView.image = image
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
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
