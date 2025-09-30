import UIKit

extension TrackersViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Layout constants
    private enum Layout {
        static let itemWidth: CGFloat = 160              // ширина ячейки
        static let itemHeight: CGFloat = 140             // высота ячейки
        static let lineSpacing: CGFloat = 16             // расстояние между рядами (вертикальное)
        static let interitemSpacing: CGFloat = 25         // расстояние между ячейками в ряду (горизонтальное)
        static let sectionInsets = UIEdgeInsets(
            top: 0, left: 10, bottom: 0, right: 10       // отступы от краёв коллекции
        )
    }
    
    // MARK: - DataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let sections = viewModel.categories.isEmpty ? 1 : viewModel.categories.count
        print("🟢 numberOfSections: \(sections)")
        return sections
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        updatePlaceholder()
        guard !viewModel.categories.isEmpty else {
            print("⚠️ No categories found, returning 0 items")
            return 0
        }

        let category = viewModel.categories[section]

        let trackersInCategory = viewModel.trackers.filter { tracker in
            if let catTitle = tracker.trackerCategory?.title {
                return catTitle == category.title
            }
            return category.title == "Мои трекеры"
        }

        print("🟢 Section \(section) ('\(category.title)') has \(trackersInCategory.count) trackers")
        return trackersInCategory.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerCell.reuseIdentifier,
            for: indexPath
        ) as? TrackerCell else {
            print("❌ Failed to dequeue TrackerCell")
            return UICollectionViewCell()
        }

        let category = viewModel.categories[indexPath.section]
        let trackersInCategory = viewModel.trackers.filter { tracker in
            if let catTitle = tracker.trackerCategory?.title {
                return catTitle == category.title
            }
            return category.title == "Мои трекеры"
        }

        guard indexPath.item < trackersInCategory.count else {
            print("❌ indexPath.item out of range: \(indexPath.item) / \(trackersInCategory.count)")
            return cell
        }

        let tracker = trackersInCategory[indexPath.item]

        print("🟢 Configuring cell for tracker: \(tracker.name) (category: \(tracker.trackerCategory?.title ?? "nil"))")

        let isCompleted = viewModel.isTrackerCompleted(tracker, on: viewModel.currentDate)
        let completedCount = viewModel.completedTrackers.filter { $0.trackerId == tracker.id }.count
        print("🟡 isCompleted: \(isCompleted), completed count: \(completedCount)")

        cell.configure(with: tracker, isCompleted: isCompleted, count: completedCount)

        let isFuture = Calendar.current.startOfDay(for: viewModel.currentDate) > Calendar.current.startOfDay(for: Date())
        cell.setCompletionEnabled(!isFuture)
        print("🔵 isFuture: \(isFuture), completion enabled: \(!isFuture)")

        cell.onToggleCompletion = { [weak self, weak collectionView] in
            guard let self = self, let collectionView = collectionView else { return }
            if isFuture { return }

            if self.viewModel.isTrackerCompleted(tracker, on: self.viewModel.currentDate) {
                print("🔴 Unmarking tracker as completed: \(tracker.name)")
                self.viewModel.unmarkTrackerAsCompleted(tracker, on: self.viewModel.currentDate)
            } else {
                print("🟢 Marking tracker as completed: \(tracker.name)")
                self.viewModel.markTrackerAsCompleted(tracker, on: self.viewModel.currentDate)
            }

            collectionView.reloadItems(at: [indexPath])
        }

        return cell
    }
    
    func addNewTracker(_ tracker: Tracker) {
        print("🟢 Adding new tracker: \(tracker.name)")
        viewModel.addTrackerToDefaultCategory(tracker)
    }
    
    // MARK: - DelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Layout.itemWidth, height: Layout.itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Layout.lineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Layout.interitemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return Layout.sectionInsets
    }
}
