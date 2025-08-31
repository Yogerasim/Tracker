import UIKit

final class CreateTrackerViewController: UIViewController {

    // MARK: - UI
    private let modalHeader = ModalHeaderView(title: "Создание трекера")
    private let habitButton = BlackButton(title: "Привычка")
    private let irregularButton = BlackButton(title: "Нерегулярное событие")

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background

        // Добавляем модальный заголовок и кнопки
        [modalHeader, habitButton, irregularButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        habitButton.addTarget(self, action: #selector(habitButtonTapped), for: .touchUpInside)
        irregularButton.addTarget(self, action: #selector(irregularButtonTapped), for: .touchUpInside)

        setupConstraints()
    }

    @objc private func habitButtonTapped() {
        let newHabitVC = NewHabitViewController()
        
        
        
        presentFullScreenSheet(newHabitVC)
    }

    @objc private func irregularButtonTapped() {
        let irregularVC = NewIrregularEventViewController()
        presentFullScreenSheet(irregularVC)
    }
    
    
    
    

    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Модальный заголовок по верхней границе и растянут по ширине родителя
            modalHeader.topAnchor.constraint(equalTo: view.topAnchor),
            modalHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            modalHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            

            // Кнопка "Привычка"
            habitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.horizontalPadding),
            habitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.horizontalPadding),
            habitButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            habitButton.heightAnchor.constraint(equalToConstant: 60),

            // Кнопка "Нерегулярное событие"
            irregularButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UIConstants.horizontalPadding),
            irregularButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.horizontalPadding),
            irregularButton.topAnchor.constraint(equalTo: habitButton.bottomAnchor, constant: AppLayout.padding),
            irregularButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
}
