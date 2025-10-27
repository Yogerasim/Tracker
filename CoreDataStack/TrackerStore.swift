import CoreData
import Foundation

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
    
    // MARK: - FRC Setup
    // MARK: - FRC Setup
    private func setupFetchedResultsController() {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        print("⚙️ [TrackerStore] Setting up FRC with request: \(request)")
        
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
            print("📥 [TrackerStore] FRC initial fetch — \(count) objects fetched")
            if let trackers = fetchedResultsController.fetchedObjects {
                trackers.forEach {
                    print("   • \($0.name ?? "nil") | category: \($0.category?.title ?? "nil")")
                }
            }
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
    
    // MARK: - Public
    func add(_ tracker: Tracker) {
        let cdTracker = TrackerCoreData(context: context)
        cdTracker.id = tracker.id
        cdTracker.name = tracker.name
        cdTracker.color = tracker.color
        cdTracker.emoji = tracker.emoji

        print("🟡 Saving Tracker: \(tracker.name), schedule: \(tracker.schedule.map { $0.rawValue })")
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

                print("🟡 Saving Tracker: \(tracker.name), schedule: \(tracker.schedule.map { $0.rawValue })")
                cdTracker.schedule = NSArray(array: tracker.schedule.map { $0.rawValue })

                if let category = tracker.trackerCategory {
                    cdTracker.category = context.object(with: category.objectID) as? TrackerCategoryCoreData
                } else {
                    cdTracker.category = nil
                }
                
                saveContext()
            }
        } catch {
            print("❌ Ошибка update Tracker: \(error)")
        }
    }
    
    
    
    func delete(_ tracker: Tracker) {
        print("🗑 [TrackerStore] delete() called for tracker: \(tracker.name)")
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        
        do {
            if let cdTracker = try context.fetch(request).first {
                print("🗑 Deleting object: \(cdTracker.name ?? "nil") from Core Data")
                context.delete(cdTracker)
                saveContext()
            } else {
                print("⚠️ delete() — tracker not found in Core Data")
            }
        } catch {
            print("❌ Ошибка delete Tracker: \(error)")
        }
    }
    
    func fetchTracker(by id: UUID) -> TrackerCoreData? {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        do {
            return try context.fetch(request).first
        } catch {
            print("❌ Ошибка fetchTracker: \(error)")
            return nil
        }
    }
    
    // MARK: - Private
    private func saveContext() {
        do {
            if context.hasChanges {
                print("💾 [TrackerStore] Saving context...")
                try context.save()
                print("✅ [TrackerStore] Context saved successfully")
            } else {
                print("ℹ️ [TrackerStore] No changes to save")
            }
        } catch {
            print("❌ Ошибка сохранения контекста: \(error)")
        }
    }
    
    
    private func notifyDelegate() {
        // если уже уведомляем — пропускаем дубликат
        guard !isNotifyingDelegate else {
            print("⚠️ [TrackerStore] Skipping duplicate notifyDelegate()")
            return
        }
        isNotifyingDelegate = true

        // Собираем свежий список трекеров (может быть тяжелая операция)
        let trackersList = getTrackers()

        print("🟢 [TrackerStore] notifyDelegate() called")
        print("   • trackers count: \(trackersList.count)")
        if trackersList.isEmpty {
            print("   ⚠️ [TrackerStore] EMPTY array passed to delegate!")
            debugFetchContents()
        } else {
            print("   • names: \(trackersList.map { $0.name })")
        }

        // Вызов делегата на главном потоке
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.didUpdateTrackers(trackersList)

            // Сбрасываем флаг чуть позже — это защищает от быстрого "дребезга" FRC
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self] in
                self?.isNotifyingDelegate = false
                print("ℹ️ [TrackerStore] notifyDelegate flag cleared")
            }
        }
    }
    private func debugFetchContents() {
        print("🔍 [TrackerStore] debugFetchContents() started")
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        
        do {
            let results = try context.fetch(request)
            print("   • Raw CoreData objects count: \(results.count)")
            for (i, item) in results.enumerated() {
                print("     \(i+1). \(item.name ?? "nil"), category: \(item.category?.title ?? "nil"), schedule: \(String(describing: item.schedule))")
            }
        } catch {
            print("❌ [TrackerStore] debugFetchContents() failed: \(error)")
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        let ms = Int(Date().timeIntervalSince1970 * 1000) // milliseconds since epoch
        print("📡 [TrackerStore] controllerDidChangeContent() at \(ms) ms")
        notifyDelegate()
    }
}

// MARK: - Mapper
private extension TrackerCoreData {
    func toTracker() -> Tracker? {
        guard let id = id,
              let name = name,
              let color = color,
              let emoji = emoji else {
            print("❌ toTracker guard failed for id: \(id?.uuidString ?? "nil")")
            return nil
        }
        
        let scheduleArray: [WeekDay]
        if let data = schedule as? Data,
           let decoded = try? JSONDecoder().decode([WeekDay].self, from: data) {
            scheduleArray = decoded
            print("💾 Decoded schedule from Core Data: \(decoded.map { $0.shortName })")
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
        
        print("🟢 Mapped TrackerCoreData -> Tracker: \(tracker.name), category: \(category?.title ?? "nil")")
        return tracker
    }
}

// MARK: - Debug
extension TrackerStore {
    func debugPrintSchedules() {
        let trackers = getTrackers()
        print("\n==============================")
        print("🗓 Проверка расписаний трекеров (\(trackers.count) шт.)")
        print("==============================")
        
        for tracker in trackers {
            if tracker.schedule.isEmpty {
                print("⚠️ \(tracker.name): расписание ПУСТО")
            } else {
                let days = tracker.schedule.map { $0.shortName }.joined(separator: ", ")
                print("✅ \(tracker.name): \(days)")
            }
        }
        print("==============================\n")
    }
}
extension TrackerStore {
    func deleteAll() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TrackerCoreData")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("⚠️ [TrackerStore] Failed to delete all trackers: \(error)")
        }
    }
}
