import CoreData
import Foundation
import Logging

final class CoreDataStack {
    
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Tracker")
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                // removed log, \(error.userInfo)")
            } else {
                // removed log")
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
            // removed log
            return
        }
        
        do {
            try context.save()
            // removed log
        } catch {
            _ = error as NSError
            // removed log, \(nserror.userInfo)")
        }
    }
}
