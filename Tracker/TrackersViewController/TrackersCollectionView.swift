import UIKit

extension TrackersViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Layout constants
    private enum Layout {
        static let itemWidth: CGFloat = 160
        static let itemHeight: CGFloat = 140
        static let lineSpacing: CGFloat = 16
        static let interitemSpacing: CGFloat = 25
        static let sectionInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        static let headerHeight: CGFloat = 30
    }
    
    // MARK: - DataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let sections = visibleCategories.isEmpty ? 1 : visibleCategories.count
        print("🟢 numberOfSections: \(sections)")
        return sections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard !visibleCategories.isEmpty else {
            print("⚠️ No categories found, returning 0 items")
            return 0
        }
        
        let category = visibleCategories[section]
        let trackersInCategory = viewModel.filteredTrackers.filter { tracker in
            tracker.trackerCategory?.title == category.title || (tracker.trackerCategory == nil && category.title == "Мои трекеры")
        }
        
        print("🟢 Section \(section) ('\(category.title)') has \(trackersInCategory.count) trackers")
        return trackersInCategory.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerCell.reuseIdentifier,
            for: indexPath
        ) as? TrackerCell else {
            print("❌ Failed to dequeue TrackerCell")
            return UICollectionViewCell()
        }
        
        guard visibleCategories.indices.contains(indexPath.section) else {
            print("❌ section index out of range: \(indexPath.section)")
            return cell
        }
        
        let category = visibleCategories[indexPath.section]
        
        let trackersInCategory = viewModel.filteredTrackers.filter { tracker in
            tracker.trackerCategory?.title == category.title ||
            (tracker.trackerCategory == nil && category.title == "Мои трекеры")
        }
        
        guard trackersInCategory.indices.contains(indexPath.item) else {
            print("❌ item index out of range: \(indexPath.item) / \(trackersInCategory.count)")
            return cell
        }
        
        let tracker = trackersInCategory[indexPath.item]
        
        let isCompleted = viewModel.isTrackerCompleted(tracker, on: viewModel.currentDate)
        let completedCount = viewModel.completedTrackers.filter { $0.trackerId == tracker.id }.count
        
        cell.configure(with: tracker, isCompleted: isCompleted, count: completedCount)
        
        let isFuture = Calendar.current.startOfDay(for: viewModel.currentDate) > Calendar.current.startOfDay(for: Date())
        cell.setCompletionEnabled(!isFuture)
        
        cell.onToggleCompletion = { [weak self, weak collectionView] in
            guard let self = self, let collectionView = collectionView else { return }
            if isFuture { return }
            
            AnalyticsService.shared.trackClick(item: "track", screen: "Main")
            
            let wasDateFilterEnabled = self.viewModel.isDateFilterEnabled
            self.viewModel.isDateFilterEnabled = false
            
            if self.viewModel.isTrackerCompleted(tracker, on: self.viewModel.currentDate) {
                
            } else {
                self.viewModel.markTrackerAsCompleted(tracker, on: self.viewModel.currentDate)
            }
            
            self.viewModel.isDateFilterEnabled = wasDateFilterEnabled
            
            collectionView.reloadItems(at: [indexPath])
        }
        
        cell.gestureRecognizers?.forEach { cell.removeGestureRecognizer($0) }
        cell.interactions.forEach { cell.removeInteraction($0) }
        let interaction = UIContextMenuInteraction(delegate: self)
        cell.addInteraction(interaction)
        
        return cell
    }
    
    func addNewTracker(_ tracker: Tracker) {
        print("🟢 Adding new tracker: \(tracker.name)")
        viewModel.addTrackerToDefaultCategory(tracker)
        updateUI()
    }
    
    func debugPrintTrackersSchedule() {
        print("🔍 Проверка расписания всех трекеров:")
        
        for tracker in viewModel.filteredTrackers {
            if !tracker.schedule.isEmpty {
                let days = tracker.schedule.map { $0.shortName }.joined(separator: ", ")
                print("🟢 \(tracker.name): \(days)")
            } else {
                print("⚠️ \(tracker.name): нет присвоенных дней недели")
            }
        }
    }
    
    // MARK: - Headers
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        
        guard kind == UICollectionView.elementKindSectionHeader else {
            print("⚪️ Unknown supplementary element kind: \(kind)")
            return UICollectionReusableView()
        }
        
        guard visibleCategories.indices.contains(indexPath.section) else {
            print("⚠️ No category at section \(indexPath.section), returning empty header")
            let emptyHeader = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: TrackerSectionHeaderView.reuseIdentifier,
                for: indexPath
            ) as? TrackerSectionHeaderView
            emptyHeader?.configure(with: "")
            return emptyHeader ?? UICollectionReusableView()
        }
        
        let category = visibleCategories[indexPath.section]
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: TrackerSectionHeaderView.reuseIdentifier,
            for: indexPath
        ) as! TrackerSectionHeaderView
        header.configure(with: category.title)
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard visibleCategories.indices.contains(section) else {
            print("⚠️ No category at section \(section), header size = .zero")
            return .zero
        }
        
        let category = visibleCategories[section]
        let trackersInCategory = viewModel.filteredTrackers.filter {
            $0.trackerCategory?.title == category.title || ($0.trackerCategory == nil && category.title == "Мои трекеры")
        }
        
        if trackersInCategory.isEmpty {
            print("⚠️ No trackers in category '\(category.title)', header size = .zero")
            return .zero
        }
        
        let size = CGSize(width: collectionView.bounds.width, height: Layout.headerHeight)
        print("🔵 Header size for section \(section): \(size)")
        return size
    }
    
    // MARK: - DelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = CGSize(width: Layout.itemWidth, height: Layout.itemHeight)
        print("📐 Cell size for \(indexPath): \(size)")
        return size
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

extension TrackersViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        
        guard
            let cell = interaction.view as? TrackerCell,
            let indexPath = ui.collectionView.indexPath(for: cell),
            visibleCategories.indices.contains(indexPath.section)
        else { return nil }
        
        let category = visibleCategories[indexPath.section]
        let trackersInCategory = viewModel.filteredTrackers.filter {
            $0.trackerCategory?.title == category.title
        }
        
        guard trackersInCategory.indices.contains(indexPath.item) else { return nil }
        let tracker = trackersInCategory[indexPath.item]
        let isPinned = tracker.trackerCategory?.title == viewModel.pinnedCategoryTitle
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let pinTitle = isPinned ? "Открепить" : "Закрепить"
            let pinAction = UIAction(title: pinTitle, image: UIImage(systemName: isPinned ? "pin.slash" : "pin")) { [weak self] _ in
                guard let self else { return }
                if isPinned {
                    self.viewModel.unpinTracker(tracker)
                } else {
                    self.viewModel.pinTracker(tracker)
                }
            }
            
            let editAction = UIAction(title: "Редактировать", image: UIImage(systemName: "pencil")) { [weak self] _ in
                guard let self else { return }
                self.viewModel.editTracker(tracker)
            }
            
            let deleteAction = UIAction(title: "Удалить", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                guard let self else { return }
                self.deleteTracker(tracker)
            }
            
            return UIMenu(title: "", children: [pinAction, editAction, deleteAction])
        }
    }
}

