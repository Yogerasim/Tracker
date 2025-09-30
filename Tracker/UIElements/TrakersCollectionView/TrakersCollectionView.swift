import UIKit

extension TrackersViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.categories.isEmpty ? 1 : viewModel.categories.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        updatePlaceholder()
        if viewModel.categories.isEmpty { return 0 }
        return viewModel.categories[section].trackers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerCell.reuseIdentifier,
            for: indexPath
        ) as? TrackerCell else {
            return UICollectionViewCell()
        }

        let tracker = viewModel.categories[indexPath.section].trackers[indexPath.item]
        let isCompleted = viewModel.isTrackerCompleted(tracker, on: viewModel.currentDate)
        let count = viewModel.completedTrackers.filter { $0.trackerId == tracker.id }.count

        cell.configure(with: tracker, isCompleted: isCompleted, count: count)

        let isFuture = Calendar.current.startOfDay(for: viewModel.currentDate) > Calendar.current.startOfDay(for: Date())
        cell.setCompletionEnabled(!isFuture)

        cell.onToggleCompletion = { [weak self, weak collectionView] in
            guard let self = self, let collectionView = collectionView else { return }
            if isFuture { return }

            if self.viewModel.isTrackerCompleted(tracker, on: self.viewModel.currentDate) {
                self.viewModel.unmarkTrackerAsCompleted(tracker, on: self.viewModel.currentDate)
            } else {
                self.viewModel.markTrackerAsCompleted(tracker, on: self.viewModel.currentDate)
            }

            collectionView.reloadItems(at: [indexPath])
        }

        return cell
    }
    
    func addNewTracker(_ tracker: Tracker) {
        viewModel.addTrackerToDefaultCategory(tracker)
    }
}
