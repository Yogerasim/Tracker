import XCTest
import SnapshotTesting
@testable import Tracker

final class TrackersViewControllerSnapshotTests: XCTestCase {
    
    var viewController: TrackersViewController!
    
    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)
        viewController = TrackersViewController()
    }
    
    override func tearDown() {
        UIView.setAnimationsEnabled(true)
        viewController = nil
        super.tearDown()
    }
    
    private func prepareForSnapshot() {
            viewController.loadViewIfNeeded()
            viewController.view.setNeedsLayout()
            viewController.view.layoutIfNeeded()
            viewController.view.frame = CGRect(origin: .zero, size: CGSize(width: 390, height: 844))
            viewController.updateUI()
            viewController.updatePlaceholder()
            viewController.updateDateText()
            RunLoop.main.run(until: Date())
        }
    
    func testTrackersViewControllerLightTheme() {
        viewController.overrideUserInterfaceStyle = .light
        prepareForSnapshot()
        withSnapshotTesting(record: false) {
            assertSnapshot(
                of: viewController,
                as: .image(
                    on: .iPhone13Pro,
                    traits: .init(userInterfaceStyle: .light)
                ),
                named: "TrackersViewController_Light"
            )
        }
    }
    
    func testTrackersViewControllerDarkTheme() {
        viewController.overrideUserInterfaceStyle = .dark
        prepareForSnapshot()

        withSnapshotTesting(record: false) {
            assertSnapshot(
                of: viewController,
                as: .image(
                    on: .iPhone13Pro,
                    traits: .init(userInterfaceStyle: .dark)
                ),
                named: "TrackersViewController_Dark"
            )
        }
    }
}
