import UIKit

final class EditCategoryView: UIView {
    let header = ModalHeaderView(
        title: NSLocalizedString("edit_category_title", comment: "Заголовок экрана редактирования категории")
    )
    let nameTextField = AppTextField(
        placeholder: NSLocalizedString("edit_category_placeholder", comment: "Плейсхолдер для поля ввода категории")
    )
    let doneButton = BlackButton(
        title: NSLocalizedString("done_button", comment: "Кнопка подтверждения")
    )
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColors.background
        setupLayout()
        configureInitialState()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { nil }
    private func setupLayout() {
        [header, nameTextField, doneButton].forEach { addSubview($0) }
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
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
            doneButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }

    private func configureInitialState() {
        doneButton.isEnabled = false
        doneButton.backgroundColor = AppColors.gray
    }

    func setCategoryName(_ text: String) {
        nameTextField.textField.text = text
    }

    var categoryName: String? {
        get { nameTextField.textField.text }
        set { nameTextField.textField.text = newValue }
    }
}
