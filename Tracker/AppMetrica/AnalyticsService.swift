import UIKit
import YandexMobileMetrica

// MARK: - AnalyticsService
final class AnalyticsService {
    
    static let shared = AnalyticsService()
    private init() {}
    
    private let defaultScreen = "Main"
    
    // MARK: - Методы трекинга
    func trackOpen(screen: String? = nil) {
        sendEvent(event: "open", screen: screen ?? defaultScreen)
    }
    
    func trackClose(screen: String? = nil) {
        sendEvent(event: "close", screen: screen ?? defaultScreen)
    }
    
    func trackClick(item: String, screen: String? = nil) {
        sendEvent(event: "click", screen: screen ?? defaultScreen, item: item)
    }
    
    // MARK: - Основной метод отправки
    private func sendEvent(event: String, screen: String, item: String? = nil) {
        var attributes: [String: Any] = [
            "event": event,
            "screen": screen
        ]
        if let item = item {
            attributes["item"] = item
        }
        
        YMMYandexMetrica.reportEvent("user_action", parameters: attributes) { error in
            print("❌ Analytics error: \(error.localizedDescription)")
            print("✅ Analytics sent: \(attributes)")
        }
    }
}


