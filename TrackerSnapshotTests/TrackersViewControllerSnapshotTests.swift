import XCTest
import SnapshotTesting
@testable import Tracker

final class TrackersViewControllerSnapshotTests: XCTestCase {
    
    var viewController: TrackersViewController!
    
    override func setUp() {
        super.setUp()
        // Убедись, что тест запускается в светлой теме
        SnapshotTesting.isRecording = false
        viewController = TrackersViewController()
    }
    
    override func tearDown() {
        viewController = nil
        super.tearDown()
    }
    
    func testTrackersViewControllerLightTheme() {
        // Настраиваем контроллер
        viewController.overrideUserInterfaceStyle = .light
        
        // Создаем снимок
        assertSnapshot(
            matching: viewController,
            as: .image(on: .iPhone13Pro),
            named: "TrackersViewController_Light"
        )
    }
}
