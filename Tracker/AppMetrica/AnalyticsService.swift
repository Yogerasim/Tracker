import Foundation
import YandexMobileMetrica

enum AnalyticsService {
    private static let defaultScreen = "Main"
    static var sendEventOverride: ((String, String, String?) -> Void)?
    static func trackOpen(screen: String? = nil) {
        sendEvent(event: "open", screen: screen ?? defaultScreen)
    }

    static func trackClose(screen: String? = nil) {
        sendEvent(event: "close", screen: screen ?? defaultScreen)
    }

    static func trackClick(item: String, screen: String? = nil) {
        sendEvent(event: "click", screen: screen ?? defaultScreen, item: item)
    }

    private static func sendEvent(event: String, screen: String, item: String? = nil) {
        if let override = sendEventOverride {
            override(event, screen, item)
            return
        }
        var attributes: [String: Any] = [
            "event": event,
            "screen": screen,
        ]
        if let item {
            attributes["item"] = item
        }
        YMMYandexMetrica.reportEvent("user_action", parameters: attributes) { _ in
        }
    }
}
