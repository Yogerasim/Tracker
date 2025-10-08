import UIKit

final class TrackerActionMenu: UIView {

    // MARK: - Callbacks
    var onPin: (() -> Void)?
    var onUnpin: (() -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    
    var tracker: Tracker?
    weak var store: TrackerStore?

    // MARK: - UI
    private lazy var stackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [pinButton, editButton, deleteButton])
        sv.axis = .vertical
        sv.spacing = 0
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.layer.cornerRadius = 12
        sv.clipsToBounds = true
        sv.backgroundColor = .systemBackground
        return sv
    }()

    private lazy var pinButton: UIButton = makeButton(title: "Закрепить", color: .systemBlue, action: #selector(pinTapped))
    private lazy var editButton: UIButton = makeButton(title: "Редактировать", color: .systemBlue, action: #selector(editTapped))
    private lazy var deleteButton: UIButton = makeButton(title: "Удалить", color: .systemRed, action: #selector(deleteTapped))

    // MARK: - State
    private var isPinned: Bool = false {
        didSet {
            updatePinButtonTitle()
        }
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupShadow()
        addTapOutsideRecognizer()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup
    private func setupUI() {
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 10
    }

    private func makeButton(title: String, color: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(color, for: .normal)
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        button.addTarget(self, action: action, for: .touchUpInside)

        let separator = UIView()
        separator.backgroundColor = UIColor.separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(separator)
        NSLayoutConstraint.activate([
            separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            separator.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
        return button
    }

    // MARK: - Public
    func configure(isPinned: Bool) {
        self.isPinned = isPinned
    }

    // MARK: - Actions
    @objc private func pinTapped() {
        if isPinned {
            onUnpin?()
        } else {
            onPin?()
        }
    }
    @objc private func editTapped() { onEdit?() }
    @objc private func deleteTapped() {
        guard let tracker = tracker else { return }
        store?.delete(tracker)
        onDelete?()  
    }

    // MARK: - Helpers
    private func updatePinButtonTitle() {
        let title = isPinned ? "Открепить" : "Закрепить"
        pinButton.setTitle(title, for: .normal)
    }

    // MARK: - Tap outside to dismiss
    private func addTapOutsideRecognizer() {
        guard let window = UIApplication.shared.windows.first else { return }
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleOutsideTap(_:)))
        tap.cancelsTouchesInView = false
        window.addGestureRecognizer(tap)
    }

    @objc private func handleOutsideTap(_ gesture: UITapGestureRecognizer) {
        guard !self.bounds.contains(gesture.location(in: self)) else { return }
        self.removeFromSuperview()
    }
}
