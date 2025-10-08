import UIKit
import CoreData
import YandexMobileMetrica

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        // 🔹 Инициализация YandexMetrica
        if let configuration = YMMYandexMetricaConfiguration(apiKey: "53e8c0c7-ca97-44d0-9b89-836ccff6b602") {
            configuration.logs = true // включаем логи SDK
            YMMYandexMetrica.activate(with: configuration)
            print("✅ YandexMetrica activated")
        } else {
            print("❌ YandexMetrica configuration failed")
        }

        // 🔹 Настройка главного окна
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = MainTabBarController()
        window?.makeKeyAndVisible()

        // 🔹 Тестовый вызов события после задержки
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            AnalyticsService.shared.trackOpen()
        }

        return true
    }
}
