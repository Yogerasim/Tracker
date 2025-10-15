import UIKit
import CoreData

final class NewHabitViewController: BaseTrackerCreationViewController {
    
    // MARK: - Callback
    var onHabitCreated: ((Tracker) -> Void)?
    
    // MARK: - Init
    init() {
        super.init(title: NSLocalizedString("new_habit.title", comment: "Новая привычка"))
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        bottomButtons.createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
    }
    
    // MARK: - Create Habit
    @objc private func createTapped() {
        bottomButtons.createButton.isEnabled = false
        
        let title = nameTextField.textValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return enableCreateButton() }
        guard let emoji = selectedEmoji else { return enableCreateButton() }
        guard let color = selectedColor else { return enableCreateButton() }
        guard let category = selectedCategory else { return enableCreateButton() }
        
        let fetchRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@ AND category == %@", title, category)
        
        if let existing = try? context.fetch(fetchRequest), !existing.isEmpty {
            print("⚠️ Такой трекер уже существует, создание пропущено")
            return enableCreateButton()
        }
        
        let tracker = TrackerCoreData(context: context)
        tracker.id = UUID()
        tracker.name = title
        tracker.emoji = emoji
        tracker.color = color.toHexString()
        tracker.category = category
        
        if let data = try? JSONEncoder().encode(selectedDays) {
            tracker.schedule = data as NSData
            print("💾 Saved schedule: \(selectedDays.map { $0.shortName })")
        }
        
        do {
            try context.save()
            print("✅ Трекер успешно сохранён в Core Data")
            dismiss(animated: true)
        } catch {
            print("❌ Ошибка сохранения трекера: \(error.localizedDescription)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.bottomButtons.createButton.isEnabled = true
        }
    }
    
    private func enableCreateButton() {
        bottomButtons.createButton.isEnabled = true
    }
}

// MARK: - TableView Delegate
extension NewHabitViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.row == 0 {
            let categoryVC = CategoryViewController(store: TrackerCategoryStore(context: context))
            categoryVC.onCategorySelected = { [weak self] category in
                self?.selectedCategory = category
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            if let sheet = categoryVC.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 16
            }
            present(categoryVC, animated: true)
        }

        if indexPath.row == 1 {
            let scheduleVC = ScheduleViewController()
            scheduleVC.selectedDays = selectedDays
            scheduleVC.onDone = { [weak self] days in
                self?.selectedDays = days
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            if let sheet = scheduleVC.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 16
            }
            present(scheduleVC, animated: true)
        }
    }
}
