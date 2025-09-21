import CoreData

final class TrackerStore {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Create
    func add(_ tracker: Tracker) {
        let cdTracker = TrackerCoreData(context: context)
        cdTracker.id = tracker.id
        cdTracker.name = tracker.name
        cdTracker.color = tracker.color
        cdTracker.emoji = tracker.emoji
        cdTracker.schedule = tracker.schedule as NSObject  
        
        saveContext()
    }
    
    // MARK: - Read
    func fetchAll() -> [Tracker] {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        
        do {
            let cdTrackers = try context.fetch(request)
            return cdTrackers.compactMap { cdTracker in
                guard let id = cdTracker.id,
                      let name = cdTracker.name,
                      let color = cdTracker.color,
                      let emoji = cdTracker.emoji,
                      let schedule = cdTracker.schedule as? [WeekDay]
                else {
                    return nil
                }
                
                return Tracker(
                    id: id,
                    name: name,
                    color: color,
                    emoji: emoji,
                    schedule: schedule
                )
            }
        } catch {
            print("❌ Ошибка fetchAll Tracker: \(error)")
            return []
        }
    }
    
    // MARK: - Delete
    func delete(_ tracker: Tracker) {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            results.forEach { context.delete($0) }
            saveContext()
        } catch {
            print("❌ Ошибка delete Tracker: \(error)")
        }
    }
    
    // MARK: - Update
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
}
