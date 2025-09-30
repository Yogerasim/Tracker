import UIKit

final class NewCategoryView: UIView {

    // MARK: - UI
    let header = ModalHeaderView(title: "Новая категория")
    let nameTextField = AppTextField(placeholder: "Введите название категории")
    let doneButton = BlackButton(title: "Готово")

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
        [header, nameTextField, doneButton].forEach { addSubview($0) }

        NSLayoutConstraint.activate([
            // Header сверху
            header.topAnchor.constraint(equalTo: topAnchor),
            header.leadingAnchor.constraint(equalTo: leadingAnchor),
            header.trailingAnchor.constraint(equalTo: trailingAnchor),

            // TextField
            nameTextField.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 5),
            nameTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),

            // DoneButton внизу
            doneButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    // MARK: - Initial State
    private func configureInitialState() {
        doneButton.isEnabled = false
        doneButton.backgroundColor = AppColors.gray
    }
}
