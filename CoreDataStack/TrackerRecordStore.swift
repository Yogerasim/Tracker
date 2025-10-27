import CoreData
import Logging

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
            // removed log records loaded")
        } catch {
            // removed log")
        }
    }
    
    var completedTrackers: [TrackerRecord] {
        guard let objects = fetchedResultsController.fetchedObjects else { return [] }
        return objects.compactMap { rec in
            guard let tracker = rec.tracker,
                  let trackerId = tracker.id,
                  let date = rec.date else { return nil }
            return TrackerRecord(trackerId: trackerId, date: date)
        }
    }
    
    func addRecord(for tracker: TrackerCoreData, date: Date) {
        let dayStart = date.startOfDayUTC()
        let dayEnd = date.endOfDayUTC()
        
        // removed log for \(tracker.name ?? "nil") | dayStartUTC=\(dayStart) | endOfDayUTC=\(dayEnd)")
        
        viewContext.perform { [weak self] in
            guard let self else { return }
            
            let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
            request.predicate = NSPredicate(
                format: "tracker == %@ AND date >= %@ AND date < %@",
                tracker, dayStart as CVarArg, dayEnd as CVarArg
            )
            
            do {
                let existingRecords = try self.viewContext.fetch(request)
                if existingRecords.isEmpty {
                    let record = TrackerRecordCoreData(context: self.viewContext)
                    record.date = dayStart
                    record.tracker = tracker
                    // removed log — saved date = \(record.date ?? Date())")
                } else {
                    // removed log")
                }
                self.saveContext(reason: "addRecord")
            } catch {
                // removed log")
            }
        }
    }
    
    func removeRecord(for tracker: TrackerCoreData, date: Date) {
        let dayStart = date.startOfDayUTC()
        let dayEnd = date.endOfDayUTC()
        
        // removed log for \(tracker.name ?? "nil") | dayStartUTC=\(dayStart) | endOfDayUTC=\(dayEnd)")
        
        viewContext.perform { [weak self] in
            guard let self else { return }
            
            let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
            request.predicate = NSPredicate(
                format: "tracker == %@ AND date >= %@ AND date < %@",
                tracker, dayStart as CVarArg, dayEnd as CVarArg
            )
            
            do {
                let results = try self.viewContext.fetch(request)
                if results.isEmpty {
                    // removed log")
                } else {
                    results.forEach { self.viewContext.delete($0) }
                    // removed log | \(dayStart)")
                }
                self.saveContext(reason: "removeRecord")
            } catch {
                // removed log")
            }
        }
    }
    
    func isCompleted(for tracker: TrackerCoreData, date: Date) -> Bool {
        let dayStart = date.startOfDayUTC()
        let dayEnd = date.endOfDayUTC()
        
        // removed log | dayStartUTC=\(dayStart) | dayEndUTC=\(dayEnd) | TZ=\(TimeZone.current.identifier)")
        
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(
            format: "tracker == %@ AND date >= %@ AND date < %@",
            tracker, dayStart as NSDate, dayEnd as NSDate
        )
        
        do {
            let count = try viewContext.count(for: request)
            // removed log: \(count > 0 ? "✅ YES" : "❌ NO") (found \(count) records)")
            return count > 0
        } catch {
            // removed log")
            return false
        }
    }
    
    private func saveContext(reason: String) {
        viewContext.perform { [weak self] in
            guard let self else { return }
            do {
                if self.viewContext.hasChanges {
                    try self.viewContext.save()
                    // removed log)")
                }
            } catch {
                // removed log): \(error)")
            }
        }
    }
}

extension TrackerRecordStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didUpdateRecords()
        }
    }
}

extension TrackerRecordStore {
    func fetchTrackerInViewContext(by id: UUID) -> TrackerCoreData? {
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
            // removed log")
            return 0
        }
    }
}

extension TrackerRecordStore {
    func addRecord(for trackerID: UUID, date: Date) {
        guard let tracker = fetchTrackerInViewContext(by: trackerID) else {
            // removed log")
            return
        }
        let dayStart = date.startOfDayUTC()
        let record = TrackerRecordCoreData(context: viewContext)
        record.tracker = tracker
        record.date = dayStart
        
        // removed log at dayStartUTC=\(dayStart)")
        self.saveContext(reason: "addRecord")
    }
    
    func deleteRecord(for trackerID: UUID, date: Date) {
        let dayStart = date.startOfDayUTC()
        guard let tracker = fetchTrackerInViewContext(by: trackerID),
              let record = tracker.records?.first(where: {
                  ($0 as? TrackerRecordCoreData)?.date == dayStart
              }) as? TrackerRecordCoreData else {
            // removed log")
            return
        }
        viewContext.delete(record)
        self.saveContext(reason: "deleteRecord")
    }
    
    func deleteAll() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TrackerRecordCoreData")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            // removed log")
        }
    }
}
