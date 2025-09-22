import CoreData

protocol TrackerRecordStoreDelegate: AnyObject {
    func didUpdateRecords()
}

final class TrackerRecordStore: NSObject {
    private let viewContext: NSManagedObjectContext
    private let backgroundContext: NSManagedObjectContext
    private let fetchedResultsController: NSFetchedResultsController<TrackerRecordCoreData>
    weak var delegate: TrackerRecordStoreDelegate?

    init(persistentContainer: NSPersistentContainer) {
        self.viewContext = persistentContainer.viewContext
        self.backgroundContext = persistentContainer.newBackgroundContext()

        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TrackerRecordCoreData.date, ascending: true)]

        self.fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: viewContext, // UI всегда слушает главный поток
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        super.init()
        fetchedResultsController.delegate = self

        // Автомердж изменений из фонового контекста в главный
        viewContext.automaticallyMergesChangesFromParent = true

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
            guard let tracker = rec.tracker,
                  let trackerId = tracker.id,
                  let date = rec.date else { return nil }
            return TrackerRecord(trackerId: trackerId, date: date)
        }
    }

    // MARK: - CRUD

    func addRecord(for tracker: TrackerCoreData, date: Date) {
        backgroundContext.perform { [weak self] in
            guard let self else { return }
            let record = TrackerRecordCoreData(context: self.backgroundContext)
            record.date = date
            record.tracker = self.backgroundContext.object(with: tracker.objectID) as? TrackerCoreData
            self.saveBackgroundContext()
        }
    }

    func removeRecord(for tracker: TrackerCoreData, date: Date) {
        backgroundContext.perform { [weak self] in
            guard let self else { return }
            let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
            request.predicate = NSPredicate(format: "tracker == %@ AND date == %@", tracker.objectID, date as CVarArg)

            do {
                let results = try self.backgroundContext.fetch(request)
                results.forEach { self.backgroundContext.delete($0) }
                self.saveBackgroundContext()
            } catch {
                print("❌ Ошибка removeRecord: \(error)")
            }
        }
    }

    func isCompleted(for tracker: TrackerCoreData, date: Date) -> Bool {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "tracker == %@ AND date == %@", tracker, date as CVarArg)

        do {
            let count = try viewContext.count(for: request) // проверка всегда через UI-контекст
            return count > 0
        } catch {
            print("❌ Ошибка isCompleted: \(error)")
            return false
        }
    }

    // MARK: - Save

    private func saveBackgroundContext() {
        do {
            if backgroundContext.hasChanges {
                try backgroundContext.save()
            }
        } catch {
            print("❌ Ошибка сохранения backgroundContext: \(error)")
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension TrackerRecordStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdateRecords()
    }
}

// MARK: - Extra

extension TrackerRecordStore {
    func fetchTracker(by id: UUID) -> TrackerCoreData? {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try viewContext.fetch(request).first
        } catch {
            print("❌ Ошибка fetchTracker(by:): \(error)")
            return nil
        }
    }
}
