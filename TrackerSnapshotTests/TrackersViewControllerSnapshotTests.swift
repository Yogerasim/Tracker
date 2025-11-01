import SnapshotTesting
import CoreData
@testable import Tracker
import XCTest
final class TrackersViewControllerSnapshotTests: XCTestCase {
    var tabBarController: MainTabBarController!
    var trackersViewController: TrackersViewController!
    var context: NSManagedObjectContext!
    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)
        context = makeInMemoryContext()
        tabBarController = MainTabBarController()
        tabBarController.loadViewIfNeeded()
        let navController = tabBarController.viewControllers?.first as? UINavigationController
        trackersViewController = navController?.viewControllers.first as? TrackersViewController
        trackersViewController.loadViewIfNeeded()
    }
    override func tearDown() {
        UIView.setAnimationsEnabled(false)
        tabBarController = nil
        trackersViewController = nil
        context = nil
        super.tearDown()
    }
    private func makeInMemoryContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "Tracker")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }
        return container.viewContext
    }
    private func prepareForSnapshot() {
        trackersViewController.loadViewIfNeeded()
        preloadTestTrackers()
        trackersViewController.recalculateVisibleCategories()
        trackersViewController.updatePlaceholder()
        trackersViewController.updateDateText()
        trackersViewController.ui.collectionView.reloadData()
        trackersViewController.view.setNeedsLayout()
        trackersViewController.view.layoutIfNeeded()
        tabBarController.view.frame = CGRect(origin: .zero, size: CGSize(width: 390, height: 844))
        RunLoop.main.run(until: Date())
    }
    private func preloadTestTrackers() {
        for i in 1...3 {
            let title = "Test Tracker \(i)"
            let color = UIColor.systemBlue
            let emoji = "🔥"
            let schedule: [Int] = [1,1,1,1,1,1,1]
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
