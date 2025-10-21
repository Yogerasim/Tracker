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
        let dayStart = Calendar.current.startOfDay(for: date)
        print("➕ [TrackerRecordStore] addRecord() START for tracker: \(tracker.name ?? "nil") | date: \(dayStart)")

        backgroundContext.perform { [weak self] in
            guard let self else { return }

            // Проверяем, есть ли уже запись на этот день
            let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
            request.predicate = NSPredicate(format: "tracker == %@ AND date >= %@ AND date < %@", tracker, dayStart as CVarArg, Calendar.current.date(byAdding: .day, value: 1, to: dayStart)! as CVarArg)

            do {
                let existingRecords = try self.backgroundContext.fetch(request)
                if existingRecords.isEmpty {
                    let record = TrackerRecordCoreData(context: self.backgroundContext)
                    record.date = dayStart
                    record.tracker = self.backgroundContext.object(with: tracker.objectID) as? TrackerCoreData
                    print("💾 [Record Added] \(tracker.name ?? "nil") — saved date = \(record.date ?? Date())")
                    print("   🟢 Record created for tracker: \(tracker.name ?? "nil") | date: \(dayStart)")
                } else {
                    print("   ⚠️ Record already exists for tracker: \(tracker.name ?? "nil") | date: \(dayStart)")
                }
                self.saveBackgroundContext(reason: "addRecord")
            } catch {
                print("❌ addRecord fetch error: \(error)")
            }
        }
    }

    func removeRecord(for tracker: TrackerCoreData, date: Date) {
        let dayStart = Calendar.current.startOfDay(for: date)
        print("➖ [TrackerRecordStore] removeRecord() START for tracker: \(tracker.name ?? "nil") | date: \(dayStart)")

        backgroundContext.perform { [weak self] in
            guard let self else { return }

            let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
            request.predicate = NSPredicate(format: "tracker == %@ AND date >= %@ AND date < %@", tracker, dayStart as CVarArg, Calendar.current.date(byAdding: .day, value: 1, to: dayStart)! as CVarArg)

            do {
                let results = try self.backgroundContext.fetch(request)
                if results.isEmpty {
                    print("   ⚠️ No records found to delete for tracker: \(tracker.name ?? "nil") | date: \(dayStart)")
                } else {
                    results.forEach {
                        print("   🗑 Deleting record for tracker: \($0.tracker?.name ?? "nil") | date: \($0.date ?? Date())")
                        self.backgroundContext.delete($0)
                    }
                    self.saveBackgroundContext(reason: "removeRecord")
                }
            } catch {
                print("❌ removeRecord fetch error: \(error)")
            }
        }
    }
    
    func isCompleted(for tracker: TrackerCoreData, date: Date) -> Bool {
        print("🧩 [TrackerRecordStore] isCompleted() called for \(tracker.name ?? "nil") — \(date.formatted(date: .numeric, time: .omitted))")

        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        
        // Берём начало и конец дня
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return false
        }
        
        // NSPredicate проверяет, что дата записи лежит в пределах дня
        request.predicate = NSPredicate(format: "tracker == %@ AND date >= %@ AND date < %@", tracker, startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            print("""
            🧮 [isCompleted] checking tracker = \(tracker.name ?? "nil")
            startOfDay = \(startOfDay)
            endOfDay = \(endOfDay)
            predicate = \(String(describing: request.predicate))
            """)
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
            print("💾 [TrackerRecordStore] saveBackgroundContext START (\(reason))")
            do {
                if backgroundContext.hasChanges {
                    try backgroundContext.save()
                    print("✅ [TrackerRecordStore] backgroundContext saved successfully (\(reason))")
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
        
        // Пробуем сначала как UUID, если не найдено — как String (для старых трекеров)
        let uuidPredicate = NSPredicate(format: "id == %@", id as CVarArg)
        let stringPredicate = NSPredicate(format: "id == %@", id.uuidString)
        
        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [uuidPredicate, stringPredicate])
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
