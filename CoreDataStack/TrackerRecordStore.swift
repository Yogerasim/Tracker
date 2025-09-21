import CoreData

protocol TrackerRecordStoreDelegate: AnyObject {
    func didUpdateRecords()
}

final class TrackerRecordStore: NSObject {
    private let context: NSManagedObjectContext
    private let fetchedResultsController: NSFetchedResultsController<TrackerRecordCoreData>
    weak var delegate: TrackerRecordStoreDelegate?

    init(context: NSManagedObjectContext) {
        self.context = context

        // Запрос
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TrackerRecordCoreData.date, ascending: true)
        ]

        
        self.fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        super.init()

        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("❌ Ошибка performFetch: \(error)")
        }
    }

    // MARK: - Access

    var completedTrackers: [TrackerRecord] {
        guard let objects = fetchedResultsController.fetchedObjects else { return [] }
        return objects.compactMap { rec in
            guard let id = rec.trackerId, let date = rec.date else { return nil }
            return TrackerRecord(trackerId: id, date: date)
        }
    }

    // MARK: - CRUD

    func addRecord(for trackerId: UUID, date: Date) {
        let record = TrackerRecordCoreData(context: context)
        record.trackerId = trackerId
        record.date = date
        saveContext()
    }

    func removeRecord(for trackerId: UUID, date: Date) {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "trackerId == %@ AND date == %@", trackerId as CVarArg, date as CVarArg)

        do {
            let results = try context.fetch(request)
            results.forEach { context.delete($0) }
            saveContext()
        } catch {
            print("❌ Ошибка removeRecord: \(error)")
        }
    }

    func isCompleted(trackerId: UUID, date: Date) -> Bool {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "trackerId == %@ AND date == %@", trackerId as CVarArg, date as CVarArg)
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("❌ Ошибка isCompleted: \(error)")
            return false
        }
    }

    // MARK: - Save

    private func saveContext() {
        do {
            if context.hasChanges { try context.save() }
        } catch {
            print("❌ Ошибка сохранения контекста: \(error)")
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension TrackerRecordStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdateRecords()
    }
}
