import UIKit
import CoreData

class TrackerCreationViewModel: BaseTrackerCreationViewController {
    
    // MARK: - Callback
    var onTrackerCreated: ((Tracker) -> Void)?
    
    // MARK: - State
    private var isCreating = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        bottomButtons.createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
    }
    
    // MARK: - Методы для наследников
    @objc func createTapped() {
        fatalError("Subclasses must override createTapped()")
    }
    
    func enableCreateButton() {
        DispatchQueue.main.async { [weak self] in
            self?.bottomButtons.createButton.isEnabled = true
        }
    }
    // MARK: - Создание трекера
    func createTracker(with schedule: [WeekDay]) {
        guard !isCreating else { return }
        isCreating = true
        bottomButtons.createButton.isEnabled = false
        
        let title = nameTextField.textValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty,
              let emoji = selectedEmoji,
              let color = selectedColor,
              let category = selectedCategory else {
            isCreating = false
            return enableCreateButton()
        }
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@ AND category == %@", title, category)
        if let existing = try? context.fetch(request), !existing.isEmpty {
            print("⚠️ Такой трекер уже существует")
            isCreating = false
            return enableCreateButton()
        }
        let trackerCD = TrackerCoreData(context: context)
        trackerCD.id = UUID()
        trackerCD.name = title
        trackerCD.emoji = emoji
        trackerCD.color = color.toHexString()
        trackerCD.category = category
        trackerCD.schedule = try? JSONEncoder().encode(schedule) as NSData
        
        do {
            try context.save()
            print("✅ Трекер сохранён")
            let tracker = Tracker(
                id: trackerCD.id!,
                name: title,
                color: color.toHexString(),
                emoji: emoji,
                schedule: schedule,
                trackerCategory: category
            )
            onTrackerCreated?(tracker)
            isCreating = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.bottomButtons.createButton.isEnabled = true
            }
            dismiss(animated: true)
        } catch {
            print("❌ Ошибка сохранения: \(error)")
            isCreating = false
            enableCreateButton()
        }
    }
}
