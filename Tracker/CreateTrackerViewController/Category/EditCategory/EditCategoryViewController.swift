import CoreData
import UIKit
final class EditCategoryViewController: UIViewController {
    private let viewModel: EditCategoryViewModel
    private let customView = EditCategoryView()
    init(viewModel: EditCategoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    @available(*, unavailable)
    required init?(coder _: NSCoder) { nil }
    override func loadView() {
        view = customView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        setupActions()
        customView.setCategoryName(viewModel.categoryName)
    }
    private func setupBindings() {
        viewModel.isButtonEnabled = { [weak self] enabled in
            self?.customView.doneButton.isEnabled = enabled
            self?.customView.doneButton.backgroundColor = enabled ? AppColors.backgroundBlackButton : AppColors.gray
        }
        viewModel.onCategoryEdited = { [weak self] in
            self?.dismiss(animated: true)
        }
    }
    private func setupActions() {
        customView.nameTextField.onTextChanged = { [weak self] text in
            self?.viewModel.categoryName = text
        }
        customView.doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
    }
    @objc private func doneTapped() {
        viewModel.saveChanges()
    }
}
