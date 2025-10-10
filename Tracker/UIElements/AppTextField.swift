import UIKit

final class AppTextField: UIView, UITextFieldDelegate {

    // MARK: - UI
    let textField: UITextField
    private let charLimitLabel: UILabel

    // Максимальное количество символов
    private let maxCharacters: Int

    // Callback при изменении текста
    var onTextChanged: ((String) -> Void)?

    // MARK: - Init
    init(placeholder: String, maxCharacters: Int = 38) {
        self.textField = UITextField()
        self.charLimitLabel = UILabel()
        self.maxCharacters = maxCharacters
        super.init(frame: .zero)

        setupUI(placeholder: placeholder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupUI(placeholder: String) {
        // Настройка текстового поля
        textField.placeholder = placeholder
        textField.backgroundColor = UIColor.systemGray6
        textField.layer.cornerRadius = AppLayout.cornerRadius
        textField.layer.masksToBounds = true
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        // Настройка подписи лимита символов
        charLimitLabel.font = AppFonts.regular(17) // caption2
        charLimitLabel.textColor = UIColor(hex: "#FD4C49") // gradientStart
        charLimitLabel.textAlignment = .center
        charLimitLabel.text = "Ограничение \(maxCharacters) символов"
        charLimitLabel.isHidden = true
        charLimitLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(textField)
        addSubview(charLimitLabel)

        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
            textField.heightAnchor.constraint(equalToConstant: 75),

            charLimitLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 4),
            charLimitLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            charLimitLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            charLimitLabel.heightAnchor.constraint(equalToConstant: 20),
            charLimitLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Actions
    @objc private func textChanged() {
        let text = textField.text ?? ""
        charLimitLabel.isHidden = text.count < maxCharacters
        onTextChanged?(text)
    }

    // MARK: - UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Блокируем ввод после maxCharacters
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        return updatedText.count <= maxCharacters
    }

    // Удобный геттер для текста
    var textValue: String {
        get { textField.text ?? "" }
        set { textField.text = newValue }
    }
    
    func setText(_ text: String) {
           textField.text = text
           textChanged() // обновляем лимит символов и вызываем callback
       }
}
