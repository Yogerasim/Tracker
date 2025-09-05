import UIKit

extension TrackersViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        updatePlaceholder()
        print("🟢 collectionView numberOfItemsInSection: \(trackers.count)")
        return trackers.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerCell.reuseIdentifier,
            for: indexPath
        ) as? TrackerCell else {
            return UICollectionViewCell()
        }

        let tracker = trackers[indexPath.item]
        let isCompleted = isTrackerCompleted(tracker, on: currentDate)
        let count = completedTrackers.filter { $0.trackerId == tracker.id }.count

        print("🟡 Настраиваем ячейку для трекера '\(tracker.name)' | isCompleted: \(isCompleted) | count: \(count)")

        cell.configure(with: tracker, isCompleted: isCompleted, count: count)

        // Проверка: будущая дата?
        let isFuture = Calendar.current.startOfDay(for: currentDate) > Calendar.current.startOfDay(for: Date())
        cell.setCompletionEnabled(!isFuture)

        cell.onToggleCompletion = { [weak self, weak collectionView] in
            guard let self = self, let collectionView = collectionView else { return }

            if isFuture {
                print("⚠️ Невозможно изменить трекер на будущую дату")
                return
            }

            if self.isTrackerCompleted(tracker, on: self.currentDate) {
                print("❌ Снимаем выполнение трекера '\(tracker.name)' на дату \(self.currentDate)")
                self.unmarkTrackerAsCompleted(tracker, on: self.currentDate)
            } else {
                print("✅ Отмечаем трекер '\(tracker.name)' выполненным на дату \(self.currentDate)")
                self.markTrackerAsCompleted(tracker, on: self.currentDate)
            }

            collectionView.reloadItems(at: [indexPath])
        }
        return cell
    }

    // MARK: - Добавление нового трекера через расширение
    func addNewTracker(_ tracker: Tracker) {
        // вызываем метод из класса
        addTrackerToDefaultCategory(tracker)
    }
}
