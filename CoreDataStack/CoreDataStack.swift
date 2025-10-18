import CoreData

final class CoreDataStack {
    
    static let shared = CoreDataStack()
    
    // MARK: - Persistent Container
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Tracker")
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                print("❌ Ошибка загрузки Persistent Store: \(error), \(error.userInfo)")
            } else {
                print("✅ Загружен Store: \(description)")
                container.viewContext.automaticallyMergesChangesFromParent = true
                container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            }
        }
        return container
    }()
    
    // MARK: - Context
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - Save Context
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("💾 Сохранено в Core Data")
            } catch {
                let nserror = error as NSError
                print("❌ Ошибка сохранения: \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
