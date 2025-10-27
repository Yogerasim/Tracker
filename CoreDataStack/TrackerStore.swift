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
        
        // removed log")
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            _ = fetchedResultsController.fetchedObjects?.count ?? 0
            // removed log objects fetched")
            if let trackers = fetchedResultsController.fetchedObjects {
                trackers.forEach {_ in 
                    // removed log | category: \($0.category?.title ?? "nil")")
                }
            }
            notifyDelegate()
        } catch {
            // removed log")
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
        
        // removed log, schedule: \(tracker.schedule.map { $0.rawValue })")
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
                
                // removed log, schedule: \(tracker.schedule.map { $0.rawValue })")
                cdTracker.schedule = NSArray(array: tracker.schedule.map { $0.rawValue })
                
                if let category = tracker.trackerCategory {
                    cdTracker.category = context.object(with: category.objectID) as? TrackerCategoryCoreData
                } else {
                    cdTracker.category = nil
                }
                
                saveContext()
            }
        } catch {
            // removed log")
        }
    }
    
    func delete(_ tracker: Tracker) {
        // removed log called for tracker: \(tracker.name)")
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        
        do {
            if let cdTracker = try context.fetch(request).first {
                // removed log from Core Data")
                context.delete(cdTracker)
                saveContext()
            } else {
                // removed log — tracker not found in Core Data")
            }
        } catch {
            // removed log")
        }
    }
    
    func fetchTracker(by id: UUID) -> TrackerCoreData? {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        do {
            return try context.fetch(request).first
        } catch {
            // removed log")
            return nil
        }
    }
    
    private func saveContext() {
        do {
            if context.hasChanges {
                // removed log
                try context.save()
                // removed log
            } else {
                // removed log
            }
        } catch {
            // removed log")
        }
    }
    
    private func notifyDelegate() {
        guard !isNotifyingDelegate else {
            // removed log")
            return
        }
        isNotifyingDelegate = true
        
        let trackersList = getTrackers()
        
        // removed log called")
        // removed log")
        if trackersList.isEmpty {
            // removed log
            debugFetchContents()
        } else {
            // removed log")
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.didUpdateTrackers(trackersList)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self] in
                self?.isNotifyingDelegate = false
                // removed log
            }
        }
    }
    
    private func debugFetchContents() {
        // removed log started")
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        
        do {
            let results = try context.fetch(request)
            // removed log")
            for (_, _) in results.enumerated() {
                // removed log. \(item.name ?? "nil"), category: \(item.category?.title ?? "nil"), schedule: \(String(describing: item.schedule))")
            }
        } catch {
            // removed log failed: \(error)")
        }
    }
}

extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        _ = Int(Date().timeIntervalSince1970 * 1000)
        // removed log at \(ms) ms")
        notifyDelegate()
    }
}

private extension TrackerCoreData {
    func toTracker() -> Tracker? {
        guard let id = id,
              let name = name,
              let color = color,
              let emoji = emoji else {
            // removed log")
            return nil
        }
        
        let scheduleArray: [WeekDay]
        if let data = schedule as? Data,
           let decoded = try? JSONDecoder().decode([WeekDay].self, from: data) {
            scheduleArray = decoded
            // removed log")
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
        
        // removed log, category: \(category?.title ?? "nil")")
        return tracker
    }
}

extension TrackerStore {
    func debugPrintSchedules() {
        let trackers = getTrackers()
        // removed log
        // removed log шт.)")
        // removed log
        
        for tracker in trackers {
            if tracker.schedule.isEmpty {
                // removed log: расписание ПУСТО")
            } else {
                _ = tracker.schedule.map { $0.shortName }.joined(separator: ", ")
                // removed log: \(days)")
            }
        }
        // removed log
    }
    
    func deleteAll() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TrackerCoreData")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            // removed log")
        }
    }
}
