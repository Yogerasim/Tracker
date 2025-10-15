import UIKit
import CoreData

final class NewIrregularEventViewController: BaseTrackerCreationViewController {

    // MARK: - Callback
    var onEventCreated: ((Tracker) -> Void)?

    // MARK: - Init
    init() {
        super.init(title: NSLocalizedString("new_irregular_event.title", comment: ""))
        // Только одна строка для категории
        tableContainer.updateHeight(forRows: 1)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        bottomButtons.createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        bottomButtons.cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        nameTextField.onTextChanged = { [weak self] text in
            let hasText = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            self?.bottomButtons.setCreateButton(enabled: hasText)
        }
    }

    // MARK: - Create Action
    @objc private func createTapped() {
        bottomButtons.createButton.isEnabled = false

        let title = nameTextField.textValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return enableCreateButton() }
        guard let emoji = selectedEmoji else { print("⚠️ Пожалуйста, выберите эмоджи"); return enableCreateButton() }
        guard let color = selectedColor else { print("⚠️ Пожалуйста, выберите цвет"); return enableCreateButton() }
        guard let selectedCategory = selectedCategory else { print("⚠️ Пожалуйста, выберите категорию"); return enableCreateButton() }

        // Проверка на существующий трекер в выбранной категории
        let fetchRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@ AND category == %@", title, selectedCategory)
        if let existing = try? context.fetch(fetchRequest), !existing.isEmpty {
            print("⚠️ Такой трекер уже существует")
            return enableCreateButton()
        }

        // Создаём Core Data объект
        let trackerCD = TrackerCoreData(context: context)
        trackerCD.id = UUID()
        trackerCD.name = title
        trackerCD.emoji = emoji
        trackerCD.color = color.toHexString()
        trackerCD.category = selectedCategory

        // Каждый день по дефолту для schedule
        do {
            let scheduleData = try JSONEncoder().encode(WeekDay.allCases.map { $0.rawValue })
            trackerCD.schedule = scheduleData as NSData // приведение к NSObject
        } catch {
            print("⚠️ Ошибка кодирования schedule: \(error)")
            enableCreateButton()
            return
        }

        // Сохраняем Core Data
        do {
            try context.save()
        } catch {
            print("⚠️ Ошибка сохранения трекера: \(error)")
            enableCreateButton()
            return
        }

        // Конвертируем в модель для UI
        let tracker = Tracker(
            id: trackerCD.id!,
            name: trackerCD.name ?? "",
            color: trackerCD.color ?? "",
            emoji: trackerCD.emoji ?? "",
            schedule: WeekDay.allCases,
            trackerCategory: selectedCategory
        )

        onEventCreated?(tracker)
        dismiss(animated: true)
        enableCreateButton()
    }

    private func enableCreateButton() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.bottomButtons.createButton.isEnabled = true
        }
    }

    @objc override func cancelTapped() {
        dismiss(animated: true)
    }

    // Таблица только с категорией
    override func numberOfRowsInTable() -> Int { 1 }

    override func tableViewCell(for tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContainerTableViewCell
        cell.configure(
            title: NSLocalizedString("new_irregular_event.category", comment: "Категория"),
            detail: selectedCategory?.title
        )
        cell.isLastCell = true
        return cell
    }

    override func didSelectRow(at indexPath: IndexPath, tableView: UITableView) {
        tableView.deselectRow(at: indexPath, animated: true)

        let categoryStore = TrackerCategoryStore(context: context)
        let categoryVC = CategoryViewController(store: categoryStore)
        categoryVC.onCategorySelected = { [weak self] category in
            self?.selectedCategory = category
            tableView.reloadRows(at: [indexPath], with: .automatic)
            self?.dismiss(animated: true)
        }

        if let sheet = categoryVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 16
        }

        present(categoryVC, animated: true)
    }
}
