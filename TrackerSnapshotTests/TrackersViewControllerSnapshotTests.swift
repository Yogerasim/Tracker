import XCTest
import SnapshotTesting
@testable import Tracker

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
        trackersViewController.view.setNeedsLayout()
        trackersViewController.view.layoutIfNeeded()
        
        tabBarController.view.frame = CGRect(origin: .zero, size: CGSize(width: 390, height: 844))
        trackersViewController.updateUI()
        trackersViewController.updatePlaceholder()
        trackersViewController.updateDateText()
        RunLoop.main.run(until: Date())
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
