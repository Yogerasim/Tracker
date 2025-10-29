import CoreData
import UIKit

class TrackerCreationViewModel: BaseTrackerCreationViewController {
    var onTrackerCreated: ((Tracker) -> Void)?
    private var isCreating = false
    override func viewDidLoad() {
        super.viewDidLoad()
        bottomButtons.createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
    }

    @objc func createTapped() {
        fatalError("Subclasses must override createTapped()")
    }

    func enableCreateButton() {
        DispatchQueue.main.async { [weak self] in
            self?.bottomButtons.createButton.isEnabled = true
        }
    }

    func createTracker(with schedule: [WeekDay]) {
        guard !isCreating else { return }
        isCreating = true
        bottomButtons.createButton.isEnabled = false
        let title = nameTextField.textValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty,
              let emoji = selectedEmoji,
              let color = selectedColor,
              let category = selectedCategory
        else {
            isCreating = false
            return enableCreateButton()
        }
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@ AND category == %@", title, category)
        if let existing = try? context.fetch(request), !existing.isEmpty {
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
            isCreating = false
            enableCreateButton()
        }
    }
}
