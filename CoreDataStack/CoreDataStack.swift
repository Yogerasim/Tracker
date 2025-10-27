import CoreData
import Foundation
import Logging

final class CoreDataStack {
    
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Tracker")
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                AppLogger.trackers.error("❌ Ошибка загрузки Persistent Store: \(error), \(error.userInfo)")
            } else {
                AppLogger.trackers.info("✅ Загружен Store: \(description)")
                container.viewContext.automaticallyMergesChangesFromParent = true
                container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        guard context.hasChanges else {
            AppLogger.trackers.info("ℹ️ Сохранение пропущено — изменений нет")
            return
        }
        
        do {
            try context.save()
            AppLogger.trackers.info("💾 Контекст сохранён в Core Data")
        } catch {
            let nserror = error as NSError
            AppLogger.trackers.error("❌ Ошибка сохранения контекста: \(nserror), \(nserror.userInfo)")
        }
    }
}
