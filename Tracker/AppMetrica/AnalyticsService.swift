import YandexMobileMetrica

final class AnalyticsService {

    static let shared = AnalyticsService()

    private init() {}

    private let screenMain = "Main"

    // MARK: - Отправка событий
    func trackOpen(screen: String = "Main") {
        sendEvent(event: "open", screen: screen)
    }

    func trackClose(screen: String = "Main") {
        sendEvent(event: "close", screen: screen)
    }

    func trackClick(item: String, screen: String = "Main") {
        sendEvent(event: "click", screen: screen, item: item)
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

        // 🔹 Отправка в AppMetrica
        YMMYandexMetrica.reportEvent("user_action", parameters: attributes) { error in
            if let error = error {
                print("❌ Analytics error: \(error.localizedDescription)")
            } else {
                print("✅ Analytics sent: \(attributes)")
            }
        }
    }
}
