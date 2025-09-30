import UIKit

final class NewCategoryViewController: UIViewController {

    private let viewModel: NewCategoryViewModel
    private let customView = NewCategoryView()

    init(viewModel: NewCategoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        setupActions()
    }

    private func setupBindings() {
        // включение/отключение кнопки
        viewModel.isButtonEnabled = { [weak self] enabled in
            self?.customView.doneButton.isEnabled = enabled
            self?.customView.doneButton.backgroundColor = enabled ? AppColors.backgroundBlackButton : AppColors.gray
        }

        // после создания категории
        viewModel.onCategoryCreated = { [weak self] category in
            self?.dismiss(animated: true)
        }
    }

    private func setupActions() {
        customView.nameTextField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        customView.doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
    }

    @objc private func textDidChange() {
        viewModel.categoryName = customView.nameTextField.text ?? ""
    }

    @objc private func doneTapped() {
        viewModel.saveCategory()
    }
}
