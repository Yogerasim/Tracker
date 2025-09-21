import CoreData

protocol TrackerStoreDelegate: AnyObject {
    func didUpdateTrackers(_ trackers: [Tracker])
}

final class TrackerStore: NSObject {
    
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TrackerCoreData>!
    
    weak var delegate: TrackerStoreDelegate?
    
    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
        setupFetchedResultsController()
    }
    
    // MARK: - FRC Setup
    private func setupFetchedResultsController() {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            notifyDelegate()
        } catch {
            print("❌ Ошибка FRC fetch: \(error)")
        }
    }
    
    // MARK: - Public
    func getTrackers() -> [Tracker] {
        guard let cdTrackers = fetchedResultsController.fetchedObjects else { return [] }
        return cdTrackers.compactMap { $0.toTracker() }
    }
    
    func add(_ tracker: Tracker) {
        let cdTracker = TrackerCoreData(context: context)
        cdTracker.id = tracker.id
        cdTracker.name = tracker.name
        cdTracker.color = tracker.color
        cdTracker.emoji = tracker.emoji
        cdTracker.schedule = tracker.schedule as NSObject
        
        saveContext()
    }
    
    func delete(_ tracker: Tracker) {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        
        do {
            if let cdTracker = try context.fetch(request).first {
                context.delete(cdTracker)
                saveContext()
            }
        } catch {
            print("❌ Ошибка delete Tracker: \(error)")
        }
    }
    
    func update(_ tracker: Tracker) {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        
        do {
            if let cdTracker = try context.fetch(request).first {
                cdTracker.name = tracker.name
                cdTracker.color = tracker.color
                cdTracker.emoji = tracker.emoji
                cdTracker.schedule = tracker.schedule as NSObject
                saveContext()
            }
        } catch {
            print("❌ Ошибка update Tracker: \(error)")
        }
    }
    
    // MARK: - Private
    private func saveContext() {
        do {
            if context.hasChanges { try context.save() }
        } catch {
            print("❌ Ошибка сохранения контекста: \(error)")
        }
    }
    
    private func notifyDelegate() {
        delegate?.didUpdateTrackers(getTrackers())
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        notifyDelegate()
    }
}

// MARK: - Mapper
private extension TrackerCoreData {
    func toTracker() -> Tracker? {
        guard let id = id,
              let name = name,
              let color = color,
              let emoji = emoji,
              let schedule = schedule as? [WeekDay] else { return nil }
        
        return Tracker(id: id, name: name, color: color, emoji: emoji, schedule: schedule)
    }
}
