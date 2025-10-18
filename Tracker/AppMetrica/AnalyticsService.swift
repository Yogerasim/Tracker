import Foundation
import YandexMobileMetrica

final class AnalyticsService {
    
    private static let defaultScreen = "Main"
    
    // MARK: - Public Methods
    
    static func trackOpen(screen: String? = nil) {
        sendEvent(event: "open", screen: screen ?? defaultScreen)
    }
    
    static func trackClose(screen: String? = nil) {
        sendEvent(event: "close", screen: screen ?? defaultScreen)
    }
    
    static func trackClick(item: String, screen: String? = nil) {
        sendEvent(event: "click", screen: screen ?? defaultScreen, item: item)
    }
    
    // MARK: - Private
    
    private static func sendEvent(event: String, screen: String, item: String? = nil) {
        var attributes: [String: Any] = [
            "event": event,
            "screen": screen
        ]
        if let item {
            attributes["item"] = item
        }
        print("📊 Analytics event: \(attributes)")
        
        YMMYandexMetrica.reportEvent("user_action", parameters: attributes) { error in
            print("❌ Analytics error: \(error.localizedDescription)")
        }
    }
}
