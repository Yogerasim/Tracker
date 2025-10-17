import UIKit
import CoreData

final class EditCategoryViewController: UIViewController {
    
    private let viewModel: EditCategoryViewModel
    private let customView = EditCategoryView()
    
    // MARK: - Init
    init(viewModel: EditCategoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Lifecycle
    override func loadView() {
        view = customView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        setupActions()
        customView.setCategoryName(viewModel.categoryName) // показываем текущее имя
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
    
    // MARK: - Actions
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
