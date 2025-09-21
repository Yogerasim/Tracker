import CoreData

final class TrackerRecordStore {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    var completedTrackers: [TrackerRecord] {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        do {
            let records = try context.fetch(request)
            return records.compactMap { rec in
                guard let id = rec.trackerId, let date = rec.date else { return nil }
                return TrackerRecord(trackerId: id, date: date)
            }
        } catch {
            print("❌ Ошибка fetch completedTrackers: \(error)")
            return []
        }
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

        do {
            let results = try context.fetch(request)
            results.forEach { context.delete($0) }
            saveContext()
        } catch {
            print("❌ Ошибка removeRecord: \(error)")
        }
    }

    func isCompleted(trackerId: UUID, date: Date) -> Bool {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "trackerId == %@ AND date == %@", trackerId as CVarArg, date as CVarArg)
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("❌ Ошибка isCompleted: \(error)")
            return false
        }
    }

    private func saveContext() {
        do {
            if context.hasChanges { try context.save() }
        } catch {
            print("❌ Ошибка сохранения контекста: \(error)")
        }
    }
}
