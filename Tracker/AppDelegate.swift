import UIKit
import CoreData
import YandexMobileMetrica
import Logging

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        if let configuration = YMMYandexMetricaConfiguration(apiKey: "53e8c0c7-ca97-44d0-9b89-836ccff6b602") {
            YMMYandexMetrica.activate(with: configuration)
            // removed log
        } else {
            // removed log
        }
        
        UIViewController.enableGlobalKeyboardDismiss()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = MainTabBarController()
        window?.makeKeyAndVisible()
        
        return true
    }
}
