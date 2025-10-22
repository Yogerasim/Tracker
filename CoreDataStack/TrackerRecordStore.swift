import CoreData

protocol TrackerRecordStoreDelegate: AnyObject {
    func didUpdateRecords()
}

final class TrackerRecordStore: NSObject {
    private let viewContext: NSManagedObjectContext
    private let fetchedResultsController: NSFetchedResultsController<TrackerRecordCoreData>
    weak var delegate: TrackerRecordStoreDelegate?
    var context: NSManagedObjectContext { viewContext }
    
    init(persistentContainer: NSPersistentContainer) {
        self.viewContext = persistentContainer.viewContext
        
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
        
        viewContext.automaticallyMergesChangesFromParent = false
        
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
        let dayStart = Calendar.current.startOfDay(for: date)
        print("➕ [TrackerRecordStore] addRecord() START for tracker: \(tracker.name ?? "nil") | date: \(dayStart)")
        
        viewContext.perform { [weak self] in
            guard let self else { return }
            
            let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
            request.predicate = NSPredicate(
                format: "tracker == %@ AND date >= %@ AND date < %@",
                tracker, dayStart as CVarArg,
                Calendar.current.date(byAdding: .day, value: 1, to: dayStart)! as CVarArg
            )
            
            do {
                let existingRecords = try self.viewContext.fetch(request)
                if existingRecords.isEmpty {
                    let record = TrackerRecordCoreData(context: self.viewContext)
                    record.date = dayStart
                    record.tracker = tracker
                    print("💾 [Record Added] \(tracker.name ?? "nil") — saved date = \(record.date ?? Date())")
                } else {
                    print("⚠️ Record already exists for tracker: \(tracker.name ?? "nil")")
                }
                self.saveContext(reason: "addRecord")
            } catch {
                print("❌ addRecord fetch error: \(error)")
            }
        }
    }

    func removeRecord(for tracker: TrackerCoreData, date: Date) {
        let dayStart = Calendar.current.startOfDay(for: date)
        print("➖ [TrackerRecordStore] removeRecord() START for tracker: \(tracker.name ?? "nil") | date: \(dayStart)")
        
        viewContext.perform { [weak self] in
            guard let self else { return }
            
            let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
            request.predicate = NSPredicate(
                format: "tracker == %@ AND date >= %@ AND date < %@",
                tracker, dayStart as CVarArg,
                Calendar.current.date(byAdding: .day, value: 1, to: dayStart)! as CVarArg
            )
            
            do {
                let results = try self.viewContext.fetch(request)
                if results.isEmpty {
                    print("⚠️ No records found to delete for tracker: \(tracker.name ?? "nil")")
                } else {
                    results.forEach { self.viewContext.delete($0) }
                    print("🗑 Deleted record for \(tracker.name ?? "nil") | \(dayStart)")
                }
                self.saveContext(reason: "removeRecord")
            } catch {
                print("❌ removeRecord fetch error: \(error)")
            }
        }
    }
    
    func isCompleted(for tracker: TrackerCoreData, date: Date) -> Bool {
        let startOfDay = Calendar.current.startOfDay(for: date)
        guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else { return false }
        
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(
            format: "tracker == %@ AND date >= %@ AND date < %@",
            tracker, startOfDay as NSDate, endOfDay as NSDate
        )
        
        do {
            let count = try viewContext.count(for: request)
            return count > 0
        } catch {
            print("❌ Ошибка isCompleted: \(error)")
            return false
        }
    }
    
    // MARK: - Save
    
    private func saveContext(reason: String) {
        viewContext.perform { [weak self] in
            guard let self else { return }
            do {
                if self.viewContext.hasChanges {
                    try self.viewContext.save()
                    DispatchQueue.main.async {
                        self.delegate?.didUpdateRecords()
                    }
                    print("✅ [TrackerRecordStore] Context saved (\(reason))")
                }
            } catch {
                print("❌ Ошибка сохранения (\(reason)): \(error)")
            }
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension TrackerRecordStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("📡 [TrackerRecordStore] controllerDidChangeContent()")
        delegate?.didUpdateRecords()
    }
}

// MARK: - Helpers

extension TrackerRecordStore {
    func fetchTracker(by id: UUID) -> TrackerCoreData? {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(
            format: "id == %@ OR id == %@", id as CVarArg, id.uuidString
        )
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
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
    
    func hasAnyTrackers() -> Bool {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.fetchLimit = 1
        let count = (try? viewContext.count(for: request)) ?? 0
        return count > 0
    }
    func fetchAllTrackersCount() -> Int {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.includesSubentities = false
        do {
            return try viewContext.count(for: request)
        } catch {
            print("❌ Ошибка подсчета трекеров: \(error)")
            return 0
        }
    }
}
// MARK: - Public Record Operations
extension TrackerRecordStore {
    
    func addRecord(for trackerID: UUID, date: Date) {
        guard let tracker = fetchTracker(by: trackerID) else {
            print("❌ [RecordStore] Tracker not found for ID \(trackerID)")
            return
        }
        let record = TrackerRecordCoreData(context: viewContext)
        record.tracker = tracker
        record.date = Calendar.current.startOfDay(for: date)
        
        saveContext()
    }
    
    func deleteRecord(for trackerID: UUID, date: Date) {
        let dayStart = Calendar.current.startOfDay(for: date)
        guard let tracker = fetchTracker(by: trackerID),
              let record = tracker.records?.first(where: {
                  ($0 as? TrackerRecordCoreData)?.date == dayStart
              }) as? TrackerRecordCoreData else {
            print("⚠️ [RecordStore] No record found to delete for \(trackerID)")
            return
        }
        viewContext.delete(record)
        saveContext()
    }
    
    func saveContext() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
            print("💾 [RecordStore] Context saved successfully")
        } catch {
            print("❌ [RecordStore] Failed to save context: \(error)")
        }
    }
}
