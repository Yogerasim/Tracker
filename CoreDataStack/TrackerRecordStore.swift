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
            AppLogger.trackers.info("📥 [TrackerRecordStore] Initial fetch — \(fetchedResultsController.fetchedObjects?.count ?? 0) records loaded")
        } catch {
            AppLogger.trackers.error("❌ Ошибка performFetch: \(error)")
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
        
        AppLogger.trackers.info("➕ [TrackerRecordStore] addRecord() for \(tracker.name ?? "nil") | dayStartUTC=\(dayStart) | endOfDayUTC=\(dayEnd)")
        
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
                    AppLogger.trackers.info("💾 [Record Added] \(tracker.name ?? "nil") — saved date = \(record.date ?? Date())")
                } else {
                    AppLogger.trackers.debug("⚠️ Record already exists for \(tracker.name ?? "nil")")
                }
                self.saveContext(reason: "addRecord")
            } catch {
                AppLogger.trackers.error("❌ addRecord fetch error: \(error)")
            }
        }
    }
    
    func removeRecord(for tracker: TrackerCoreData, date: Date) {
        let dayStart = date.startOfDayUTC()
        let dayEnd = date.endOfDayUTC()
        
        AppLogger.trackers.info("➖ [TrackerRecordStore] removeRecord() for \(tracker.name ?? "nil") | dayStartUTC=\(dayStart) | endOfDayUTC=\(dayEnd)")
        
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
                    AppLogger.trackers.debug("⚠️ No records found to delete for tracker: \(tracker.name ?? "nil")")
                } else {
                    results.forEach { self.viewContext.delete($0) }
                    AppLogger.trackers.info("🗑 Deleted record for \(tracker.name ?? "nil") | \(dayStart)")
                }
                self.saveContext(reason: "removeRecord")
            } catch {
                AppLogger.trackers.error("❌ removeRecord fetch error: \(error)")
            }
        }
    }
    
    func isCompleted(for tracker: TrackerCoreData, date: Date) -> Bool {
        let dayStart = date.startOfDayUTC()
        let dayEnd = date.endOfDayUTC()
        
        AppLogger.trackers.debug("🔍 Checking isCompleted for \(tracker.name ?? "nil") | dayStartUTC=\(dayStart) | dayEndUTC=\(dayEnd) | TZ=\(TimeZone.current.identifier)")
        
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(
            format: "tracker == %@ AND date >= %@ AND date < %@",
            tracker, dayStart as NSDate, dayEnd as NSDate
        )
        
        do {
            let count = try viewContext.count(for: request)
            AppLogger.trackers.info("📊 isCompleted result for \(tracker.name ?? "nil"): \(count > 0 ? "✅ YES" : "❌ NO") (found \(count) records)")
            return count > 0
        } catch {
            AppLogger.trackers.error("❌ Ошибка isCompleted: \(error)")
            return false
        }
    }
    
    private func saveContext(reason: String) {
        viewContext.perform { [weak self] in
            guard let self else { return }
            do {
                if self.viewContext.hasChanges {
                    try self.viewContext.save()
                    AppLogger.trackers.info("✅ [TrackerRecordStore] Context saved (\(reason))")
                }
            } catch {
                AppLogger.trackers.error("❌ Ошибка сохранения (\(reason)): \(error)")
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
            AppLogger.trackers.error("❌ Ошибка подсчета трекеров: \(error)")
            return 0
        }
    }
}

extension TrackerRecordStore {
    func addRecord(for trackerID: UUID, date: Date) {
        guard let tracker = fetchTrackerInViewContext(by: trackerID) else {
            AppLogger.trackers.error("❌ [RecordStore] Tracker not found for ID \(trackerID)")
            return
        }
        let dayStart = date.startOfDayUTC()
        let record = TrackerRecordCoreData(context: viewContext)
        record.tracker = tracker
        record.date = dayStart
        
        AppLogger.trackers.info("💾 [RecordStore] Added by ID \(trackerID) at dayStartUTC=\(dayStart)")
        self.saveContext(reason: "addRecord")
    }
    
    func deleteRecord(for trackerID: UUID, date: Date) {
        let dayStart = date.startOfDayUTC()
        guard let tracker = fetchTrackerInViewContext(by: trackerID),
              let record = tracker.records?.first(where: {
                  ($0 as? TrackerRecordCoreData)?.date == dayStart
              }) as? TrackerRecordCoreData else {
            AppLogger.trackers.debug("⚠️ [RecordStore] No record found to delete for \(trackerID)")
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
            AppLogger.trackers.debug("⚠️ [TrackerRecordStore] Failed to delete all records: \(error)")
        }
    }
}
