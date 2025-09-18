import CoreData

final class TrackerCategoryStoreStack {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Create
    func add(_ category: TrackerCategory) {
        // TODO: сохранить TrackerCategory в Core Data
    }
    
    // MARK: - Read
    func fetchAll() -> [TrackerCategory] {
        // TODO: достать все TrackerCategory из Core Data
        return []
    }
    
    // MARK: - Delete
    func delete(_ category: TrackerCategory) {
        // TODO: удалить TrackerCategory из Core Data
    }
}
