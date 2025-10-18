import CoreData

protocol TrackerRecordStoreDelegate: AnyObject {
    func didUpdateRecords()
}

final class TrackerRecordStore: NSObject {
    let viewContext: NSManagedObjectContext
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
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        super.init()
        fetchedResultsController.delegate = self
        
        viewContext.automaticallyMergesChangesFromParent = true
        
        do {
            try fetchedResultsController.performFetch()
            print("📥 [TrackerRecordStore] Initial fetch — \(fetchedResultsController.fetchedObjects?.count ?? 0) records loaded")
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
        print("➕ [TrackerRecordStore] addRecord() for tracker: \(tracker.name ?? "nil") | date: \(date)")
        backgroundContext.perform { [weak self] in
            guard let self else { return }
            let record = TrackerRecordCoreData(context: self.backgroundContext)
            record.date = date
            record.tracker = self.backgroundContext.object(with: tracker.objectID) as? TrackerCoreData
            self.saveBackgroundContext(reason: "removeRecord")
        }
    }
    
    func removeRecord(for tracker: TrackerCoreData, date: Date) {
        print("➖ [TrackerRecordStore] removeRecord() for tracker: \(tracker.name ?? "nil") | date: \(date)")
        backgroundContext.perform { [weak self] in
            guard let self else { return }
            let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
            request.predicate = NSPredicate(format: "tracker == %@ AND date == %@", tracker.objectID, date as CVarArg)
            
            do {
                let results = try self.backgroundContext.fetch(request)
                print("   🔍 Found \(results.count) records to delete")
                results.forEach { print("   🗑 Deleting record for tracker: \($0.tracker?.name ?? "nil") | date: \($0.date ?? Date())")
                    self.backgroundContext.delete($0)
                }
                self.saveBackgroundContext(reason: "removeRecord")
            } catch {
                print("❌ Ошибка removeRecord: \(error)")
            }
        }
    }
    
    func isCompleted(for tracker: TrackerCoreData, date: Date) -> Bool {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "tracker == %@ AND date == %@", tracker, date as CVarArg)
        
        do {
            let count = try viewContext.count(for: request)
            print("🔎 [TrackerRecordStore] isCompleted() for \(tracker.name ?? "nil") → \(count > 0 ? "✅ YES" : "❌ NO")")
            return count > 0
        } catch {
            print("❌ Ошибка isCompleted: \(error)")
            return false
        }
    }
    
    // MARK: - Save
    
    private func saveBackgroundContext(reason: String) {
        backgroundContext.performAndWait {
            do {
                if backgroundContext.hasChanges {
                    print("💾 [TrackerRecordStore] Saving backgroundContext (\(reason))...")
                    try backgroundContext.save()
                    print("✅ [TrackerRecordStore] backgroundContext saved successfully")
                    DispatchQueue.main.async { [weak self] in
                        self?.delegate?.didUpdateRecords()
                    }
                } else {
                    print("ℹ️ [TrackerRecordStore] No changes to save (\(reason))")
                }
            } catch {
                print("❌ Ошибка сохранения backgroundContext (\(reason)): \(error)")
            }
        }
    }
    
    func hasAnyTrackers() -> Bool {
        viewContext.performAndWait {
            let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
            request.fetchLimit = 1
            do {
                let count = try viewContext.count(for: request)
                return count > 0
            } catch {
                print("❌ Ошибка при проверке наличия трекеров: \(error)")
                return false
            }
        }
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate

extension TrackerRecordStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("📡 [TrackerRecordStore] controllerDidChangeContent() → delegate only")
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
    
    func fetchAllRecords() -> [TrackerRecord] {
        guard let objects = fetchedResultsController.fetchedObjects else { return [] }
        return objects.compactMap { rec in
            guard let tracker = rec.tracker,
                  let trackerId = tracker.id,
                  let date = rec.date else { return nil }
            return TrackerRecord(trackerId: trackerId, date: date)
        }
    }
}
// MARK: - Notifications

extension Notification.Name {
    static let trackerRecordsDidChange = Notification.Name("trackerRecordsDidChange")
    static let trackersDidChange = Notification.Name("trackersDidChange")
}

// MARK: - Debug helpers

extension TrackerRecordStore {
    func debugPrintAllRecords() {
        print("\n==============================")
        print("📘 [TrackerRecordStore] All TrackerRecords")
        print("==============================")
        guard let objects = fetchedResultsController.fetchedObjects else {
            print("⚠️ No fetched objects")
            return
        }
        for (i, record) in objects.enumerated() {
            print("\(i+1). \(record.tracker?.name ?? "nil") — \(record.date ?? Date())")
        }
        print("==============================\n")
    }
}
