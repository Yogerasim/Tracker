import UIKit

extension TrackersViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        updatePlaceholder()
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

        cell.configure(with: tracker, isCompleted: isCompleted, count: count)
        cell.onToggleCompletion = { [weak self, weak collectionView] in
            guard let self = self, let collectionView = collectionView else { return }
            if self.currentDate > Date() { return }

            if self.isTrackerCompleted(tracker, on: self.currentDate) {
                self.unmarkTrackerAsCompleted(tracker, on: self.currentDate)
            } else {
                self.markTrackerAsCompleted(tracker, on: self.currentDate)
            }
            collectionView.reloadItems(at: [indexPath])
        }
        return cell
    }
}
