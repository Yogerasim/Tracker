import SnapshotTesting
@testable import Tracker
import XCTest

final class TrackersViewControllerSnapshotTests: XCTestCase {
    var tabBarController: MainTabBarController!
    var trackersViewController: TrackersViewController!
    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)
        tabBarController = MainTabBarController()
        let navController = tabBarController.viewControllers?.first as? UINavigationController
        trackersViewController = navController?.viewControllers.first as? TrackersViewController
    }

    override func tearDown() {
        UIView.setAnimationsEnabled(true)
        tabBarController = nil
        trackersViewController = nil
        super.tearDown()
    }

    private func prepareForSnapshot() {
        tabBarController.loadViewIfNeeded()
        trackersViewController.loadViewIfNeeded()
        trackersViewController.viewModel.loadData()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        preloadTestRecords()
        trackersViewController.recalculateVisibleCategories()
        trackersViewController.updatePlaceholder()
        trackersViewController.updateDateText()
        trackersViewController.ui.collectionView.reloadData()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        refreshAllVisibleCells()
        trackersViewController.view.setNeedsLayout()
        trackersViewController.view.layoutIfNeeded()
        tabBarController.view.frame = CGRect(origin: .zero, size: CGSize(width: 390, height: 844))
        RunLoop.main.run(until: Date())
    }

    private func preloadTestRecords() {
        let recordStore = trackersViewController.viewModel.recordStore
        let trackers = trackersViewController.viewModel.trackers
        guard let first = trackers.first else { return }
        let calendar = Calendar.current
        let today = Date()
        let dates = (0 ..< 3).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
        for date in dates {
            recordStore.addRecord(for: first.id, date: date)
        }
    }

    private func refreshAllVisibleCells() {
        let collectionView = trackersViewController.ui.collectionView
        for cell in collectionView.visibleCells {
            (cell as? TrackerCell)?.refreshCellState()
        }
    }

    func testTrackersViewControllerLightTheme() {
        tabBarController.overrideUserInterfaceStyle = .light
        prepareForSnapshot()
        assertSnapshot(
            of: tabBarController,
            as: .image(on: .iPhone13Pro, traits: .init(userInterfaceStyle: .light)),
            named: "TrackersViewController_Light"
        )
    }

    func testTrackersViewControllerDarkTheme() {
        tabBarController.overrideUserInterfaceStyle = .dark
        prepareForSnapshot()
        assertSnapshot(
            of: tabBarController,
            as: .image(on: .iPhone13Pro, traits: .init(userInterfaceStyle: .dark)),
            named: "TrackersViewController_Dark"
        )
    }
}
