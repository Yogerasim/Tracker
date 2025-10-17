import CoreData
import Foundation

protocol TrackerStoreDelegate: AnyObject {
    func didUpdateTrackers(_ trackers: [Tracker])
}

final class TrackerStore: NSObject {

    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<TrackerCoreData>!

    weak var delegate: TrackerStoreDelegate?

    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
        setupFetchedResultsController()
    }

    // MARK: - FRC Setup
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

        // ✅ Сохраняем schedule как NSArray<Int>
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

                // Обновление schedule напрямую
                print("🟡 Saving Tracker: \(tracker.name), schedule: \(tracker.schedule.map { $0.rawValue })")
                cdTracker.schedule = NSArray(array: tracker.schedule.map { $0.rawValue })

                // Обновление категории
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
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)

        do {
            if let cdTracker = try context.fetch(request).first {
                context.delete(cdTracker)
                saveContext()
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
            if context.hasChanges { try context.save() }
        } catch {
            print("❌ Ошибка сохранения контекста: \(error)")
        }
    }

    private func notifyDelegate() {
        let trackersList = getTrackers()
        print("🟢 Notifying delegate, trackers: \(trackersList.map { $0.name })")
        delegate?.didUpdateTrackers(trackersList)
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("📡 TrackerStore content changed — notifying delegate + NotificationCenter")
        notifyDelegate()
        // 🔹 Добавляем уведомление, чтобы статистика или другие экраны могли обновляться
        NotificationCenter.default.post(name: .trackersDidChange, object: nil)
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

        // ✅ JSON-декодирование schedule
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

