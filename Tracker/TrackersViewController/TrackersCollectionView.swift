import UIKit
extension TrackersViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private enum Layout {
        static let itemWidth: CGFloat = 160
        static let itemHeight: CGFloat = 140
        static let lineSpacing: CGFloat = 16
        static let interitemSpacing: CGFloat = 25
        static let sectionInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        static let headerHeight: CGFloat = 30
    }
    func numberOfSections(in _: UICollectionView) -> Int {
        if visibleCategories.isEmpty && !filtersViewModel.filteredTrackers.isEmpty {
            return 1
        } else {
            return visibleCategories.count
        }
    }
    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if visibleCategories.isEmpty { return 0 }
        let category = visibleCategories[section]
        return filtersViewModel.filteredTrackers.filter {
            $0.trackerCategory?.title == category.title
        }.count
    }
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerCell.reuseIdentifier,
            for: indexPath
        ) as? TrackerCell else {
            return UICollectionViewCell()
        }
        guard visibleCategories.indices.contains(indexPath.section) else { return cell }
        let category = visibleCategories[indexPath.section]
        let trackersInCategory = filtersViewModel.filteredTrackers.filter {
            $0.trackerCategory?.title == category.title
        }
        guard trackersInCategory.indices.contains(indexPath.item) else { return cell }
        let tracker = trackersInCategory[indexPath.item]
        let cellViewModel = viewModel.makeCellViewModel(for: tracker)
        cellViewModel.updateCurrentDate(filtersViewModel.selectedDate)
        cell.configure(with: cellViewModel)
        let isFuture = viewModel.currentDate.startOfDayUTC() > Date().startOfDayUTC()
        cell.setCompletionEnabled(!isFuture)
        cell.onToggleCompletion = { [weak self] completed in
            guard let self = self else { return }
            self.filtersViewModel.updateSingleTracker(tracker, completed: completed)
            self.refreshCell(for: tracker)
        }
        contextMenuController?.addInteraction(to: cell)
        return cell
    }
    func addNewTracker(_ tracker: Tracker) {
        let categoryTitle = tracker.trackerCategory?.title ?? "Без категории"
        viewModel.addTracker(tracker, to: categoryTitle)
        filtersViewModel.applyAllFilters(for: filtersViewModel.selectedDate) 
        ui.collectionView.reloadData()
    }
    func refreshCell(for tracker: Tracker) {
        guard let indexPath = indexPathForTracker(tracker) else { return }
        DispatchQueue.main.async {
            UIView.performWithoutAnimation {
                self.ui.collectionView.reloadItems(at: [indexPath])
            }
        }
    }
    func indexPathForTracker(_ tracker: Tracker) -> IndexPath? {
        for (sectionIndex, category) in visibleCategories.enumerated() {
            let trackers = filtersViewModel.filteredTrackers.filter {
                $0.trackerCategory?.title == category.title
            }
            if let itemIndex = trackers.firstIndex(where: { $0.id == tracker.id }) {
                return IndexPath(item: itemIndex, section: sectionIndex)
            }
        }
        return nil
    }
    func debugPrintTrackersSchedule() {
        for tracker in filtersViewModel.filteredTrackers {
            if !tracker.schedule.isEmpty {
                _ = tracker.schedule.map { $0.shortName }.joined(separator: ", ")
            }
        }
    }
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView
    {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: TrackerSectionHeaderView.reuseIdentifier,
            for: indexPath
        ) as! TrackerSectionHeaderView
        if visibleCategories.indices.contains(indexPath.section) {
            let category = visibleCategories[indexPath.section]
            header.configure(with: category.title)
        } else {
            header.configure(with: "")
        }
        return header
    }
    func collectionView(_ collectionView: UICollectionView,
                        layout _: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize
    {
        guard visibleCategories.indices.contains(section) else { return .zero }
        let category = visibleCategories[section]
        let trackersInCategory = filtersViewModel.filteredTrackers.filter {
            $0.trackerCategory?.title == category.title
        }
        return trackersInCategory.isEmpty ? .zero : CGSize(width: collectionView.bounds.width, height: Layout.headerHeight)
    }
    func collectionView(_: UICollectionView,
                        layout _: UICollectionViewLayout,
                        sizeForItemAt _: IndexPath) -> CGSize
    {
        CGSize(width: Layout.itemWidth, height: Layout.itemHeight)
    }
    func collectionView(_: UICollectionView,
                        layout _: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt _: Int) -> CGFloat
    {
        Layout.lineSpacing
    }
    func collectionView(_: UICollectionView,
                        layout _: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt _: Int) -> CGFloat
    {
        Layout.interitemSpacing
    }
    func collectionView(_: UICollectionView,
                        layout _: UICollectionViewLayout,
                        insetForSectionAt _: Int) -> UIEdgeInsets
    {
        Layout.sectionInsets
    }
}
extension TrackersViewController: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let category = visibleCategories[indexPath.section]
        let trackersInCategory = filtersViewModel.filteredTrackers.filter {
            $0.trackerCategory?.title == category.title
        }
        let tracker = trackersInCategory[indexPath.item]
        AnalyticsService.trackClick(item: tracker.name, screen: "Main")
    }
}
