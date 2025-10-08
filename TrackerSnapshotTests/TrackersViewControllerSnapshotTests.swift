import XCTest
import SnapshotTesting
@testable import Tracker

final class TrackersViewControllerSnapshotTests: XCTestCase {
    
    var viewController: TrackersViewController!
    
    override func setUp() {
        super.setUp()
        SnapshotTesting.isRecording = false   
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
        // Убедимся, что layout завершён
        viewController.view.setNeedsLayout()
        viewController.view.layoutIfNeeded()
        // Явно задаём размер в случае нестабильности:
        viewController.view.frame = CGRect(origin: .zero, size: CGSize(width: 390, height: 844))
    }
    
    func testTrackersViewControllerLightTheme() {
        viewController.overrideUserInterfaceStyle = .light
        prepareForSnapshot()
        
        assertSnapshot(
            matching: viewController,
            as: .image(
                on: .iPhone13Pro,
                traits: .init(userInterfaceStyle: .light)
            ),
            named: "TrackersViewController_Light"
        )
    }
    
    func testTrackersViewControllerDarkTheme() {
        viewController.overrideUserInterfaceStyle = .dark
        prepareForSnapshot()
        
        assertSnapshot(
            matching: viewController,
            as: .image(
                on: .iPhone13Pro,
                traits: .init(userInterfaceStyle: .dark)
            ),
            named: "TrackersViewController_Dark"
        )
    }
}
