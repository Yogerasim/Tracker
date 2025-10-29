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
            
            if let trackers = fetchedResultsController.fetchedObjects {
                trackers.forEach {_ in
                    
                }
            }
            notifyDelegate()
        } catch {
            
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

        // Сохраняем schedule корректно
        cdTracker.schedule = try? JSONEncoder().encode(tracker.schedule) as NSData
        AppLogger.coreData.info("💾 Добавлен schedule для \(tracker.name): \(tracker.schedule.map { $0.rawValue })")

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

                // Обновляем schedule через JSON
                cdTracker.schedule = try? JSONEncoder().encode(tracker.schedule) as NSData
                AppLogger.coreData.info("🔄 Обновлён schedule для \(tracker.name): \(tracker.schedule.map { $0.rawValue })")

                if let category = tracker.trackerCategory {
                    cdTracker.category = context.object(with: category.objectID) as? TrackerCategoryCoreData
                } else {
                    cdTracker.category = nil
                }

                saveContext()
            }
        } catch {
            AppLogger.coreData.error("❌ Ошибка при обновлении трекера: \(error.localizedDescription)")
        }
    }
    
    func delete(_ tracker: Tracker) {
        
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        
        do {
            if let cdTracker = try context.fetch(request).first {
                
                context.delete(cdTracker)
                saveContext()
            } else {
                
            }
        } catch {
            
        }
    }
    
    func fetchTracker(by id: UUID) -> TrackerCoreData? {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        do {
            return try context.fetch(request).first
        } catch {
            
            return nil
        }
    }
    
    private func saveContext() {
        do {
            if context.hasChanges {
                
                try context.save()
                
            } else {
                
            }
        } catch {
            
        }
    }
    
    private func notifyDelegate() {
        AppLogger.coreData.info("[TrackerStore] 🔔 notifyDelegate вызван — обновляем делегата")

        guard !isNotifyingDelegate else {
            AppLogger.coreData.info("[TrackerStore] 🚫 notifyDelegate пропущен — уже уведомляем")
            return
        }
        isNotifyingDelegate = true
        
        let trackersList = getTrackers()
        
        
        
        if trackersList.isEmpty {
            
            debugFetchContents()
        } else {
            
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.didUpdateTrackers(trackersList)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self] in
                self?.isNotifyingDelegate = false
                
            }
        }
    }
    
    private func debugFetchContents() {
        
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        
        do {
            let results = try context.fetch(request)
            
            for (_, _) in results.enumerated() {
                
            }
        } catch {
            
        }
    }
}

extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        AppLogger.coreData.info("[TrackerStore] ⚙️ controllerDidChangeContent вызван — данные изменились")
        notifyDelegate()
    }
}

private extension TrackerCoreData {
    func toTracker() -> Tracker? {
        guard let id = id,
              let name = name,
              let color = color,
              let emoji = emoji else {
            return nil
        }

        let scheduleArray: [WeekDay]
        if let data = schedule as? Data {
            scheduleArray = (try? JSONDecoder().decode([WeekDay].self, from: data)) ?? []
        } else if let arr = schedule as? [NSNumber] {
            scheduleArray = arr.compactMap { WeekDay(rawValue: $0.intValue) }
        } else {
            scheduleArray = []
        }

        let tracker = Tracker(
            id: id,
            name: name,
            color: color,
            emoji: emoji,
            schedule: scheduleArray,
            trackerCategory: category
        )
        return tracker
    }
}
extension TrackerStore {
    func debugPrintSchedules() {
        let trackers = getTrackers()
        
        
        
        
        for tracker in trackers {
            if tracker.schedule.isEmpty {
                
            } else {
                _ = tracker.schedule.map { $0.shortName }.joined(separator: ", ")
                
            }
        }
        
    }
    
    func deleteAll() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TrackerCoreData")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            
        }
    }
}
