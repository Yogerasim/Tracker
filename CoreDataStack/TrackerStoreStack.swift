import CoreData

final class TrackerStoreStack {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Create
    func add(_ tracker: Tracker) {
        // TODO: сохранить Tracker в Core Data
    }
    
    // MARK: - Read
    func fetchAll() -> [Tracker] {
        // TODO: достать все Tracker из Core Data
        return []
    }
    
    // MARK: - Delete
    func delete(_ tracker: Tracker) {
        // TODO: удалить Tracker из Core Data
    }
}
