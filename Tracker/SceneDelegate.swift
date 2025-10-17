import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        let mainTabBar = MainTabBarController()
        window.rootViewController = mainTabBar
        self.window = window
        window.makeKeyAndVisible()

        // Проверяем, был ли показан онбординг
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

        if !hasSeenOnboarding {
            DispatchQueue.main.async {
                let onboardingVC = OnboardingViewController()
                onboardingVC.modalPresentationStyle = .fullScreen
                mainTabBar.present(onboardingVC, animated: false)

                UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
            }
        }
    }
}
