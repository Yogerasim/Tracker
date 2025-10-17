import UIKit

final class ButonsPanelView: UIView {
    
    // MARK: - UI
    let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("cancel_button", comment: "Отмена"), for: .normal)
        button.setTitleColor(AppColors.errorRed, for: .normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = AppColors.errorRed.cgColor
        button.layer.cornerRadius = AppLayout.cornerRadius
        button.titleLabel?.font = AppFonts.subheadline
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("create_button", comment: "Создать"), for: .normal)
        button.backgroundColor = AppColors.backgroundBlackButton
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = AppLayout.cornerRadius
        button.titleLabel?.font = AppFonts.subheadline
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [cancelButton, createButton])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Init
    var onCreateTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        backgroundColor = AppColors.background
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        setCreateButton(enabled: false)
    }
    
    @objc private func createTapped() {
        onCreateTapped?()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public
    func setCreateButton(enabled: Bool) {
        createButton.isEnabled = enabled
        createButton.alpha = enabled ? 1.0 : 0.5
    }
    
    // MARK: - Layout
    private func setupLayout() {
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UIConstants.horizontalPadding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UIConstants.horizontalPadding),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
}
