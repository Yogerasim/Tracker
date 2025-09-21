import CoreData

final class TrackerCategoryStore {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Create
    func add(_ category: TrackerCategory) {
        let cdCategory = TrackerCategoryCoreData(context: context)
        cdCategory.id = category.id
        cdCategory.title = category.title
        saveContext()
    }
    
    // MARK: - Read
    func fetchAll() -> [TrackerCategory] {
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        
        do {
            let cdCategories = try context.fetch(request)
            return cdCategories.map { cdCategory in
                TrackerCategory(
                    id: cdCategory.id!,
                    title: cdCategory.title!,
                    trackers: [] 
                )
            }
        } catch {
            print("❌ Ошибка fetchAll TrackerCategory: \(error)")
            return []
        }
    }
    
    // MARK: - Delete
    func delete(_ category: TrackerCategory) {
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", category.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            results.forEach { context.delete($0) }
            saveContext()
        } catch {
            print("❌ Ошибка delete TrackerCategory: \(error)")
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
}

extension TrackerCategoryStore {
    func addTracker(_ tracker: Tracker, to categoryTitle: String) {
        // Ищем категорию
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", categoryTitle)
        
        do {
            let results = try context.fetch(request)
            let cdCategory: TrackerCategoryCoreData
            if let existing = results.first {
                cdCategory = existing
            } else {
                cdCategory = TrackerCategoryCoreData(context: context)
                cdCategory.id = UUID()
                cdCategory.title = categoryTitle
            }

            // Создаем трекер
            let cdTracker = TrackerCoreData(context: context)
            cdTracker.id = tracker.id
            cdTracker.name = tracker.name
            cdTracker.color = tracker.color
            cdTracker.emoji = tracker.emoji
            cdTracker.schedule = tracker.schedule as NSObject

            // Добавляем в категорию
            var trackersSet = cdCategory.trackers as? Set<TrackerCoreData> ?? []
            trackersSet.insert(cdTracker)
            cdCategory.trackers = trackersSet as NSSet

            saveContext()
        } catch {
            print("❌ Ошибка добавления трекера в категорию: \(error)")
        }
    }
}
