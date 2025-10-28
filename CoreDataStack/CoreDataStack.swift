import CoreData
import Foundation
import Logging

final class CoreDataStack {
    
    static let shared = CoreDataStack()
    
    // MARK: - Init
    private init() {
        ValueTransformer.setValueTransformer(
            WeekDayArrayTransformer(),
            forName: NSValueTransformerName("WeekDayArrayTransformer")
        )
        
        AppLogger.coreData.info("[CoreData] ✅ ValueTransformer зарегистрирован: WeekDayArrayTransformer")
    }
    
    // MARK: - Persistent Container
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Tracker")
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                AppLogger.coreData.error("[CoreData] ❌ Ошибка при загрузке PersistentStore: \(error), \(error.userInfo)")
            } else {
                AppLogger.coreData.info("[CoreData] 💾 PersistentStore загружен: \(description.url?.lastPathComponent ?? "неизвестно")")
            }
        }
        
        let context = container.viewContext
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        AppLogger.coreData.debug("[CoreData] ⚙️ Настроен viewContext (mergePolicy = ObjectTrump)")
        
        return container
    }()
    
    // MARK: - Context Accessor
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - Save
    func saveContext() {
        let context = persistentContainer.viewContext
        guard context.hasChanges else {
            AppLogger.coreData.debug("[CoreData] 💡 Нет изменений для сохранения")
            return
        }
        
        do {
            try context.save()
            AppLogger.coreData.info("[CoreData] 💾 Контекст успешно сохранён")
        } catch {
            let nsError = error as NSError
            AppLogger.coreData.error("[CoreData] ❌ Ошибка при сохранении контекста: \(nsError), \(nsError.userInfo)")
        }
    }
}
