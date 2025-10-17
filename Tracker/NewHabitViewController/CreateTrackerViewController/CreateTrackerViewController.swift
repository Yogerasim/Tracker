import UIKit

final class CreateTrackerViewController: UIViewController {
    
    // MARK: - UI
    private let modalHeader = ModalHeaderView(
        title: NSLocalizedString("create_tracker_title", comment: "Заголовок создания трекера")
    )
    private let habitButton = BlackButton(
        title: NSLocalizedString("habit_button_title", comment: "Кнопка для создания привычки")
    )
    private let irregularButton = BlackButton(
        title: NSLocalizedString("irregular_button_title", comment: "Кнопка для создания нерегулярного события")
    )
    
    // MARK: - Callback
    var onTrackerCreated: ((Tracker) -> Void)?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        
        [modalHeader, habitButton, irregularButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        habitButton.addTarget(self, action: #selector(habitButtonTapped), for: .touchUpInside)
        irregularButton.addTarget(self, action: #selector(irregularButtonTapped), for: .touchUpInside)
        
        setupConstraints()
    }
    
    // MARK: - Actions
    
    @objc private func habitButtonTapped() {
        let newHabitVC = NewHabitViewController()
        newHabitVC.onHabitCreated = { [weak self] tracker in
            self?.onTrackerCreated?(tracker)
        }
        presentFullScreenSheet(newHabitVC)
    }
    
    @objc private func irregularButtonTapped() {
        let irregularVC = NewIrregularEventViewController()
        irregularVC.onEventCreated = { [weak self] tracker in
            self?.onTrackerCreated?(tracker)
        }
        presentFullScreenSheet(irregularVC)
    }
    
    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([

            modalHeader.topAnchor.constraint(equalTo: view.topAnchor),
            modalHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            modalHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            habitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.horizontalPadding),
            habitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.horizontalPadding),
            habitButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            habitButton.heightAnchor.constraint(equalToConstant: 60),
            
            irregularButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.horizontalPadding),
            irregularButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.horizontalPadding),
            irregularButton.topAnchor.constraint(equalTo: habitButton.bottomAnchor, constant: AppLayout.padding),
            irregularButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
}
