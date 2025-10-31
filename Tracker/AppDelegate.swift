import CoreData
import Logging
import UIKit
import YandexMobileMetrica
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if let configuration = YMMYandexMetricaConfiguration(apiKey: "53e8c0c7-ca97-44d0-9b89-836ccff6b602") {
            YMMYandexMetrica.activate(with: configuration)
        } else {}
        UIViewController.enableGlobalKeyboardDismiss()
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = MainTabBarController()
        window?.makeKeyAndVisible()
        return true
    }
}
