import CoreData

final class TrackerRecordStore {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
    }

    func addRecord(for trackerId: UUID, date: Date) {
        let record = TrackerRecordCoreData(context: context)
        record.trackerId = trackerId
        record.date = date
        saveContext()
    }

    func removeRecord(for trackerId: UUID, date: Date) {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "trackerId == %@ AND date == %@", trackerId as CVarArg, date as CVarArg)
        if let found = try? context.fetch(request).first {
            context.delete(found)
            saveContext()
        }
    }

    func isCompleted(trackerId: UUID, date: Date) -> Bool {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "trackerId == %@ AND date == %@", trackerId as CVarArg, date as CVarArg)
        return (try? context.fetch(request))?.isEmpty == false
    }

    func fetchAll() -> [TrackerRecord] {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        guard let entities = try? context.fetch(request) else { return [] }
        return entities.compactMap { $0.toModel() }
    }

    private func saveContext() {
        if context.hasChanges {
            try? context.save()
        }
    }
}

extension TrackerRecordCoreData {
    func toModel() -> TrackerRecord? {
        guard let tId = trackerId, let d = date else { return nil }
        return TrackerRecord(trackerId: tId, date: d)
    }
}
