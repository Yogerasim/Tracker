import Logging
enum AppLogger {
    static let ui = Logger(label: "com.myapp.ui")
    static let trackers = Logger(label: "com.myapp.trackers")
    static let analytics = Logger(label: "com.myapp.analytics")
    static let coreData = Logger(label: "com.myapp.coredata")
    static func setup() {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            if label == "com.myapp.trackers" {
                handler.logLevel = .info
            } else {
                handler.logLevel = .critical
            }
            return handler
        }
    }
}
