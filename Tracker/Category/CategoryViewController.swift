import UIKit

final class CategoryViewController: UIViewController {

    private let header = ModalHeaderView(title: "Категория")
    private let placeholderView = PlaceholderView()
    private let addButton = BlackButton(title: "Добавить категорию")

    private let viewModel: CategoryViewModel

    init(viewModel: CategoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        setupLayout()
        bindViewModel()
        viewModel.loadCategories()
    }

    private func setupLayout() {
        [header, placeholderView, addButton].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
          
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            placeholderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            placeholderView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            placeholderView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),

       
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func bindViewModel() {
        placeholderView.configure(text: viewModel.placeholderText)
        addButton.setTitle(viewModel.buttonTitle, for: .normal)

        addButton.addTarget(self, action: #selector(addCategoryTapped), for: .touchUpInside)

        viewModel.onCategoriesChanged = { [weak self] categories in
            self?.placeholderView.isHidden = !categories.isEmpty
        }

        viewModel.onShowNewCategory = { [weak self] in
            guard let self = self else { return }
            let newCategoryVM = NewCategoryViewModel()
            let newCategoryVC = NewCategoryViewController(viewModel: newCategoryVM)
            self.present(newCategoryVC, animated: true)
        }
    }

    @objc private func addCategoryTapped() {
        viewModel.addCategoryTapped()
    }
}
