import UIKit

final class NewCategoryView: UIView {
    
    // MARK: - UI
    let header = ModalHeaderView(
        title: NSLocalizedString("new_category_title", comment: "")
    )
    
    let nameTextField = AppTextField(
        placeholder: NSLocalizedString("new_category_placeholder", comment: "")
    )
    
    let doneButton = BlackButton(
        title: NSLocalizedString("done_button", comment: "")
    )
    
    let placeholderView = PlaceholderView()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColors.background
        setupLayout()
        configureInitialState()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Layout
    private func setupLayout() {
        [header, nameTextField, doneButton, placeholderView].forEach { addSubview($0) }
        [header, nameTextField, doneButton, placeholderView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: leadingAnchor),
            header.trailingAnchor.constraint(equalTo: trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 90),
            
            nameTextField.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 10),
            nameTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),
            
            doneButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        placeholderView.configure(
            imageName: "Star",
            text: NSLocalizedString("new_category_placeholder_text", comment: "")
        )
        placeholderView.isHidden = true
        
        NSLayoutConstraint.activate([
            placeholderView.centerXAnchor.constraint(equalTo: centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 0),
            placeholderView.topAnchor.constraint(greaterThanOrEqualTo: nameTextField.bottomAnchor, constant: 20),
            placeholderView.bottomAnchor.constraint(lessThanOrEqualTo: doneButton.topAnchor, constant: -20)
        ])
        
        placeholderView.setContentHuggingPriority(.required, for: .vertical)
        placeholderView.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    // MARK: - Initial State
    private func configureInitialState() {
        doneButton.isEnabled = false
        doneButton.backgroundColor = AppColors.gray
    }
}
