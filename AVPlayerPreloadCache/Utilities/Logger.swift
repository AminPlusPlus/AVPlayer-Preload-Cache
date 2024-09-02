import os

struct Logger {
    static func logMessage(_ message: String, level: LogLevel = .info) {
        let logger = os.Logger()
        switch level {
        case .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        case .fault:
            logger.fault("\(message, privacy: .public)")
        }
    }
}

enum LogLevel {
    case debug
    case info
    case error
    case fault
}
