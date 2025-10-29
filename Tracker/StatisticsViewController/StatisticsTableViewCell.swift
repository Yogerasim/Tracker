import UIKit

final class StatisticsTableViewCell: UITableViewCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.bold(34)
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? .white
                : AppColors.backgroundBlackButton
        }
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.medium(12)
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? .white
                : AppColors.backgroundBlackButton
        }
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let gradientLayer = CAGradientLayer()
    private let shapeLayer = CAShapeLayer()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setupLayout()
        setupGradientBorder()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { nil }
    func configure(title: Int, subtitle: String) {
        titleLabel.text = String(title)
        subtitleLabel.text = subtitle
    }

    private func setupLayout() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: 90),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
    }

    private func setupGradientBorder() {
        gradientLayer.colors = [
            AppColors.gradientRed.cgColor,
            AppColors.gradientGreen.cgColor,
            AppColors.gradientBlue.cgColor,
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        shapeLayer.lineWidth = 1
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.black.cgColor
        gradientLayer.mask = shapeLayer
        contentView.layer.addSublayer(gradientLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = contentView.bounds
        let path = UIBezierPath(roundedRect: contentView.bounds, cornerRadius: 16)
        shapeLayer.path = path.cgPath
    }
}
