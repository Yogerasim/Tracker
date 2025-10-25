import UIKit

final class AppTextField: UIView, UITextFieldDelegate {
    
    // MARK: - UI
    let textField: CustomTextField
    private let charLimitLabel: UILabel
    private let clearButton: UIButton
    
    private let maxCharacters: Int
    
    var onTextChanged: ((String) -> Void)?
    
    // MARK: - Init
    init(placeholder: String, maxCharacters: Int = 38) {
        self.textField = CustomTextField()
        self.charLimitLabel = UILabel()
        self.clearButton = UIButton(type: .system)
        self.maxCharacters = maxCharacters
        super.init(frame: .zero)
        
        setupUI(placeholder: placeholder)
        setupClearButton()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
    
    // MARK: - UI Setup
    private func setupUI(placeholder: String) {

        textField.placeholder = placeholder
        textField.backgroundColor = UIColor.systemGray6
        textField.layer.cornerRadius = AppLayout.cornerRadius
        textField.layer.masksToBounds = true
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        
        charLimitLabel.font = AppFonts.regular(17)
        charLimitLabel.textColor = UIColor(hex: "#FD4C49")
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
    
    // MARK: - Clear Button
    private func setupClearButton() {
        clearButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        clearButton.tintColor = UIColor.systemGray3
        clearButton.addTarget(self, action: #selector(clearText), for: .touchUpInside)
        
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 17, height: 17))
        clearButton.frame = container.bounds
        container.addSubview(clearButton)
        
        textField.rightView = container
        textField.rightViewMode = .whileEditing
    }
    
    @objc private func clearText() {
        textField.text = ""
        textChanged()
    }
    
    // MARK: - Actions
    @objc private func textChanged() {
        let text = textField.text ?? ""
        charLimitLabel.isHidden = text.count < maxCharacters
        onTextChanged?(text)
    }
    
    // MARK: - UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        return updatedText.count <= maxCharacters
    }
    
    var textValue: String {
        get { textField.text ?? "" }
        set { textField.text = newValue }
    }
    
    func setText(_ text: String) {
        textField.text = text
        textChanged()
    }
}

// MARK: - Custom UITextField для сдвига rightView
final class CustomTextField: UITextField {
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.rightViewRect(forBounds: bounds)
        rect.origin.x -= 10
        rect.origin.y += 0
        return rect
    }
}
