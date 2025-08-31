import UIKit

final class TrackerCell: UICollectionViewCell {
    static let reuseIdentifier = "TrackerCell"
    var onToggleCompletion: (() -> Void)?

    // MARK: - UI
    private let cardView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()

    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        label.layer.cornerRadius = 12 
        label.layer.masksToBounds = true
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.numberOfLines = 2
        label.textAlignment = .left
        label.textColor = .white
        return label
    }()

    private let bottomContainer: UIView = UIView()

    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .black
        return label
    }()

    private lazy var toggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 17
        button.setTitle("+", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        button.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(cardView)
        contentView.addSubview(bottomContainer)

        cardView.addSubview(emojiLabel)
        cardView.addSubview(titleLabel)

        bottomContainer.addSubview(dayLabel)
        bottomContainer.addSubview(toggleButton)

        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Actions
    @objc private func toggleTapped() { onToggleCompletion?() }

    // MARK: - Configure
    func configure(with tracker: Tracker, isCompleted: Bool, count: Int) {
        emojiLabel.text = tracker.emoji
        titleLabel.text = tracker.name
        dayLabel.text = "\(count) день"

        if let c = UIColor(hexString: tracker.color) {
            cardView.backgroundColor = c
            toggleButton.backgroundColor = c
        } else {
            cardView.backgroundColor = .lightGray
            toggleButton.backgroundColor = .lightGray
        }

        let symbol = isCompleted ? "✓" : "+"
        toggleButton.setTitle(symbol, for: .normal)
    }

    // MARK: - Layout
    private func setupConstraints() {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.translatesAutoresizingMaskIntoConstraints = false
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        toggleButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // cardView сверху
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.heightAnchor.constraint(equalToConstant: 90),

            // emojiLabel слева сверху карточки
            emojiLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 8),
            emojiLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            emojiLabel.widthAnchor.constraint(equalToConstant: 24),
            emojiLabel.heightAnchor.constraint(equalToConstant: 24),

            // titleLabel слева снизу карточки
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -8),

            // bottomContainer под карточкой
            bottomContainer.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 4),
            bottomContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomContainer.heightAnchor.constraint(equalToConstant: 34),

            // dayLabel слева в bottomContainer
            dayLabel.centerYAnchor.constraint(equalTo: bottomContainer.centerYAnchor),
            dayLabel.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 8),

            // toggleButton справа в bottomContainer
            toggleButton.centerYAnchor.constraint(equalTo: bottomContainer.centerYAnchor),
            toggleButton.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -12),
            toggleButton.widthAnchor.constraint(equalToConstant: 34),
            toggleButton.heightAnchor.constraint(equalToConstant: 34)
        ])
    }
}

// MARK: - UIColor + Hex
private extension UIColor {
    convenience init?(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6, let value = UInt64(hex, radix: 16) else { return nil }
        self.init(
            red: CGFloat((value & 0xFF0000) >> 16)/255,
            green: CGFloat((value & 0x00FF00) >> 8)/255,
            blue: CGFloat(value & 0x0000FF)/255,
            alpha: 1
        )
    }
}
