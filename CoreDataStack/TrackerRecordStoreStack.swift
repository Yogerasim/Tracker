import CoreData

final class TrackerRecordStoreStack {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Create
    func add(_ record: TrackerRecord) {
        // TODO: сохранить TrackerRecord в Core Data
    }
    
    // MARK: - Read
    func fetchAll() -> [TrackerRecord] {
        // TODO: достать все TrackerRecord из Core Data
        return []
    }
    
    // MARK: - Delete
    func delete(_ record: TrackerRecord) {
        // TODO: удалить TrackerRecord из Core Data
    }
}
