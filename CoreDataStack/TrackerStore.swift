import CoreData
import Foundation
import Logging

protocol TrackerStoreDelegate: AnyObject {
    func didUpdateTrackers(_ trackers: [Tracker])
}

final class TrackerStore: NSObject {
    
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TrackerCoreData>!
    private var isNotifyingDelegate = false
    
    weak var delegate: TrackerStoreDelegate?
    
    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
        setupFetchedResultsController()
    }
    
    private func setupFetchedResultsController() {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        AppLogger.trackers.info("⚙️ [TrackerStore] Setting up FRC with request: \(request)")
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            let count = fetchedResultsController.fetchedObjects?.count ?? 0
            AppLogger.trackers.info("📥 [TrackerStore] FRC initial fetch — \(count) objects fetched")
            if let trackers = fetchedResultsController.fetchedObjects {
                trackers.forEach {
                    AppLogger.trackers.info("   • \($0.name ?? "nil") | category: \($0.category?.title ?? "nil")")
                }
            }
            notifyDelegate()
        } catch {
            AppLogger.trackers.error("❌ Ошибка FRC fetch: \(error)")
        }
    }
    
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
        
        AppLogger.trackers.info("🟡 Saving Tracker: \(tracker.name), schedule: \(tracker.schedule.map { $0.rawValue })")
        cdTracker.schedule = NSArray(array: tracker.schedule.map { $0.rawValue })
        
        if let category = tracker.trackerCategory {
            cdTracker.category = context.object(with: category.objectID) as? TrackerCategoryCoreData
        }
        
        saveContext()
    }
    
    func update(_ tracker: Tracker) {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        
        do {
            if let cdTracker = try context.fetch(request).first {
                cdTracker.name = tracker.name
                cdTracker.color = tracker.color
                cdTracker.emoji = tracker.emoji
                
                AppLogger.trackers.info("🟡 Saving Tracker: \(tracker.name), schedule: \(tracker.schedule.map { $0.rawValue })")
                cdTracker.schedule = NSArray(array: tracker.schedule.map { $0.rawValue })
                
                if let category = tracker.trackerCategory {
                    cdTracker.category = context.object(with: category.objectID) as? TrackerCategoryCoreData
                } else {
                    cdTracker.category = nil
                }
                
                saveContext()
            }
        } catch {
            AppLogger.trackers.error("❌ Ошибка update Tracker: \(error)")
        }
    }
    
    func delete(_ tracker: Tracker) {
        AppLogger.trackers.info("🗑 [TrackerStore] delete() called for tracker: \(tracker.name)")
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        
        do {
            if let cdTracker = try context.fetch(request).first {
                AppLogger.trackers.info("🗑 Deleting object: \(cdTracker.name ?? "nil") from Core Data")
                context.delete(cdTracker)
                saveContext()
            } else {
                AppLogger.trackers.debug("⚠️ delete() — tracker not found in Core Data")
            }
        } catch {
            AppLogger.trackers.error("❌ Ошибка delete Tracker: \(error)")
        }
    }
    
    func fetchTracker(by id: UUID) -> TrackerCoreData? {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        do {
            return try context.fetch(request).first
        } catch {
            AppLogger.trackers.error("❌ Ошибка fetchTracker: \(error)")
            return nil
        }
    }
    
    private func saveContext() {
        do {
            if context.hasChanges {
                AppLogger.trackers.info("💾 [TrackerStore] Saving context...")
                try context.save()
                AppLogger.trackers.info("✅ [TrackerStore] Context saved successfully")
            } else {
                AppLogger.trackers.info("ℹ️ [TrackerStore] No changes to save")
            }
        } catch {
            AppLogger.trackers.error("❌ Ошибка сохранения контекста: \(error)")
        }
    }
    
    private func notifyDelegate() {
        guard !isNotifyingDelegate else {
            AppLogger.trackers.debug("⚠️ [TrackerStore] Skipping duplicate notifyDelegate()")
            return
        }
        isNotifyingDelegate = true
        
        let trackersList = getTrackers()
        
        AppLogger.trackers.info("🟢 [TrackerStore] notifyDelegate() called")
        AppLogger.trackers.info("   • trackers count: \(trackersList.count)")
        if trackersList.isEmpty {
            AppLogger.trackers.debug("   ⚠️ [TrackerStore] EMPTY array passed to delegate!")
            debugFetchContents()
        } else {
            AppLogger.trackers.info("   • names: \(trackersList.map { $0.name })")
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.didUpdateTrackers(trackersList)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self] in
                self?.isNotifyingDelegate = false
                AppLogger.trackers.info("ℹ️ [TrackerStore] notifyDelegate flag cleared")
            }
        }
    }
    
    private func debugFetchContents() {
        AppLogger.trackers.debug("🔍 [TrackerStore] debugFetchContents() started")
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        
        do {
            let results = try context.fetch(request)
            AppLogger.trackers.debug("   • Raw CoreData objects count: \(results.count)")
            for (i, item) in results.enumerated() {
                AppLogger.trackers.debug("     \(i+1). \(item.name ?? "nil"), category: \(item.category?.title ?? "nil"), schedule: \(String(describing: item.schedule))")
            }
        } catch {
            AppLogger.trackers.error("❌ [TrackerStore] debugFetchContents() failed: \(error)")
        }
    }
}

extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        let ms = Int(Date().timeIntervalSince1970 * 1000)
        AppLogger.trackers.info("📡 [TrackerStore] controllerDidChangeContent() at \(ms) ms")
        notifyDelegate()
    }
}

private extension TrackerCoreData {
    func toTracker() -> Tracker? {
        guard let id = id,
              let name = name,
              let color = color,
              let emoji = emoji else {
            AppLogger.trackers.error("❌ toTracker guard failed for id: \(id?.uuidString ?? "nil")")
            return nil
        }
        
        let scheduleArray: [WeekDay]
        if let data = schedule as? Data,
           let decoded = try? JSONDecoder().decode([WeekDay].self, from: data) {
            scheduleArray = decoded
            AppLogger.trackers.info("💾 Decoded schedule from Core Data: \(decoded.map { $0.shortName })")
        } else {
            scheduleArray = []
        }
        
        let category = self.category
        
        let tracker = Tracker(
            id: id,
            name: name,
            color: color,
            emoji: emoji,
            schedule: scheduleArray,
            trackerCategory: category
        )
        
        AppLogger.trackers.info("🟢 Mapped TrackerCoreData -> Tracker: \(tracker.name), category: \(category?.title ?? "nil")")
        return tracker
    }
}

extension TrackerStore {
    func debugPrintSchedules() {
        let trackers = getTrackers()
        AppLogger.trackers.info("\n==============================")
        AppLogger.trackers.info("🗓 Проверка расписаний трекеров (\(trackers.count) шт.)")
        AppLogger.trackers.info("==============================")
        
        for tracker in trackers {
            if tracker.schedule.isEmpty {
                AppLogger.trackers.debug("⚠️ \(tracker.name): расписание ПУСТО")
            } else {
                let days = tracker.schedule.map { $0.shortName }.joined(separator: ", ")
                AppLogger.trackers.info("✅ \(tracker.name): \(days)")
            }
        }
        AppLogger.trackers.info("==============================\n")
    }
    
    func deleteAll() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TrackerCoreData")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            AppLogger.trackers.debug("⚠️ [TrackerStore] Failed to delete all trackers: \(error)")
        }
    }
}
