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
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let sections = visibleCategories.isEmpty ? 1 : visibleCategories.count
        AppLogger.trackers.info("🟢 numberOfSections: \(sections)")
        return sections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard !visibleCategories.isEmpty else { return 0 }
        let category = visibleCategories[section]
        let trackersInCategory = filtersViewModel.filteredTrackers.filter {
            $0.trackerCategory?.title == category.title ||
            ($0.trackerCategory == nil && category.title == "Мои трекеры")
        }
        return trackersInCategory.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerCell.reuseIdentifier,
            for: indexPath
        ) as? TrackerCell else { return UICollectionViewCell() }
        
        guard visibleCategories.indices.contains(indexPath.section) else { return cell }
        let category = visibleCategories[indexPath.section]
        let trackersInCategory = filtersViewModel.filteredTrackers.filter {
            $0.trackerCategory?.title == category.title ||
            ($0.trackerCategory == nil && category.title == "Мои трекеры")
        }
        guard trackersInCategory.indices.contains(indexPath.item) else { return cell }
        
        let tracker = trackersInCategory[indexPath.item]
        let cellViewModel = viewModel.makeCellViewModel(for: tracker)
        cell.configure(with: cellViewModel)
        
        let isFuture = viewModel.currentDate.startOfDayUTC() > Date().startOfDayUTC()
        cell.setCompletionEnabled(!isFuture)
        
        contextMenuController?.addInteraction(to: cell)
        return cell
    }
    
    func addNewTracker(_ tracker: Tracker) {
        AppLogger.trackers.info("🟢 Adding new tracker: \(tracker.name)")
        viewModel.addTrackerToDefaultCategory(tracker)
        filtersViewModel.applyFilter()
        ui.collectionView.reloadData()
    }
    
    func debugPrintTrackersSchedule() {
        AppLogger.trackers.info("🔍 Проверка расписания всех трекеров:")
        for tracker in filtersViewModel.filteredTrackers {
            if !tracker.schedule.isEmpty {
                let days = tracker.schedule.map { $0.shortName }.joined(separator: ", ")
                AppLogger.trackers.info("🟢 \(tracker.name): \(days)")
            } else {
                AppLogger.trackers.warning("⚠️ \(tracker.name): нет присвоенных дней недели")
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
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
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard visibleCategories.indices.contains(section) else { return .zero }
        let category = visibleCategories[section]
        let trackersInCategory = filtersViewModel.filteredTrackers.filter {
            $0.trackerCategory?.title == category.title ||
            ($0.trackerCategory == nil && category.title == "Мои трекеры")
        }
        return trackersInCategory.isEmpty ? .zero : CGSize(width: collectionView.bounds.width, height: Layout.headerHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: Layout.itemWidth, height: Layout.itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        Layout.lineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        Layout.interitemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        Layout.sectionInsets
    }
}

// MARK: - Delegate
extension TrackersViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let category = visibleCategories[indexPath.section]
        let trackersInCategory = filtersViewModel.filteredTrackers.filter {
            $0.trackerCategory?.title == category.title ||
            ($0.trackerCategory == nil && category.title == "Мои трекеры")
        }
        let tracker = trackersInCategory[indexPath.item]
        AppLogger.trackers.info("🟣 Tap on tracker: \(tracker.name)")
        AnalyticsService.trackClick(item: tracker.name, screen: "Main")
    }
}
