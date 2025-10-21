import CoreData

protocol TrackerCategoryStoreDelegate: AnyObject {
    func didUpdateCategories()
}

final class TrackerCategoryStore: NSObject {
    
    // MARK: - Properties
    private let context: NSManagedObjectContext
    private let fetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData>
    weak var delegate: TrackerCategoryStoreDelegate?
    
    private let mappingErrorMessage = "⚠️ Ошибка маппинга TrackerCategoryCoreData: отсутствует id или title"
    
    // MARK: - Init
    init(context: NSManagedObjectContext) {
        self.context = context
        let request = TrackerCategoryStore.makeFetchRequest()
        
        self.fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        super.init()
        self.fetchedResultsController.delegate = self
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            print("❌ Ошибка performFetch категорий: \(error)")
        }
    }
    
    // MARK: - Public API
    var categories: [TrackerCategory] {
        guard let objects = fetchedResultsController.fetchedObjects else { return [] }
        var result = objects.compactMap { toCategory(from: $0) }
        let pinnedTitle = NSLocalizedString("trackers.pinned_category", comment: "Название категории закрепленных трекеров")
        result.sort {
            if $0.title == pinnedTitle { return true }
            if $1.title == pinnedTitle { return false }
            return $0.title.localizedCompare($1.title) == .orderedAscending
        }
        
        return result
    }
    
    func add(_ category: TrackerCategory) {
        let cdCategory = TrackerCategoryCoreData(context: context)
        cdCategory.id = category.id
        cdCategory.title = category.title
        saveContext()
    }
    
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
    
    func addTracker(_ tracker: Tracker, to categoryTitle: String) {
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
            
            let cdTracker = TrackerCoreData(context: context)
            cdTracker.id = tracker.id
            cdTracker.name = tracker.name
            cdTracker.color = tracker.color
            cdTracker.emoji = tracker.emoji
            cdTracker.schedule = tracker.schedule as NSObject
            
            var trackersSet = cdCategory.trackers as? Set<TrackerCoreData> ?? []
            trackersSet.insert(cdTracker)
            cdCategory.trackers = trackersSet as NSSet
            
            saveContext()
        } catch {
            print("❌ Ошибка добавления трекера в категорию: \(error)")
        }
    }
    func fetchCategories() -> [TrackerCategoryCoreData] {
        return fetchedResultsController.fetchedObjects ?? []
    }
    
    func add(_ category: TrackerCategoryCoreData) {
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", category.id! as CVarArg)
        if let results = try? context.fetch(request), results.isEmpty {
            let newCategory = TrackerCategoryCoreData(context: context)
            newCategory.id = category.id
            newCategory.title = category.title
            saveContext()
        }
    }
    
    func moveTracker(_ tracker: Tracker, to categoryTitle: String) {
        guard
            let categoryCoreData = fetchCategoryByTitle(categoryTitle),
            let trackerCoreData = fetchTracker(by: tracker.id)
        else { return }

        trackerCoreData.category = categoryCoreData
        saveContext()
    }
    
    
    // MARK: - Private
    
    private func fetchCategoryByTitle(_ title: String) -> TrackerCategoryCoreData? {
        let request = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", title)
        return try? context.fetch(request).first
    }
    
    private func fetchTracker(by id: UUID) -> TrackerCoreData? {
        let request = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(request).first
    }
    
    private static func makeFetchRequest() -> NSFetchRequest<TrackerCategoryCoreData> {
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TrackerCategoryCoreData.title, ascending: true)]
        return request
    }
    
    private func toCategory(from cdCategory: TrackerCategoryCoreData) -> TrackerCategory? {
        guard let id = cdCategory.id,
              let title = cdCategory.title else {
            print(mappingErrorMessage)
            return nil
        }
        let trackers: [Tracker] = []
        return TrackerCategory(id: id, title: title, trackers: trackers)
    }
    
    private func saveContext() {
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            print("❌ Ошибка сохранения контекста: \(error)")
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdateCategories()
    }
}
