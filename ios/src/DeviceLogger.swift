import OSLog

let LOG = DeviceLogger()

/// Make all data in log messages public for debug builds
struct DeviceLogger {
    let logger: Logger

    init() {
        logger = Logger(
            subsystem: Bundle.main.bundleIdentifier!,
            category: "generic")
    }

    func debug(
        _ message: String, line: Int = #line, fileID: String = #fileID
    ) {
        #if DEBUG
            logger.debug(
                "\(fileID, privacy: .public):\(line, privacy: .public):\t\(message, privacy: .public)"
            )
        #else
            logger.debug("\(fileID):\(line):\t\(message)")
        #endif
    }

    func info(
        _ message: String, line: Int = #line, fileID: String = #fileID
    ) {
        #if DEBUG
            logger.info(
                "\(fileID, privacy: .public):\(line, privacy: .public):\t\(message, privacy: .public)"
            )
        #else
            logger.info("\(fileID):\(line):\t\(message)")
        #endif
    }

    func warning(
        _ message: String, line: Int = #line, fileID: String = #fileID
    ) {
        #if DEBUG
            logger.warning(
                "\(fileID, privacy: .public):\(line, privacy: .public):\t\(message, privacy: .public)"
            )
        #else
            logger.warning("\(fileID):\(line):\t\(message)")
        #endif
    }

    func error(_ message: String, line: Int = #line, fileID: String = #fileID) {
        #if DEBUG
            logger.error(
                "\(fileID, privacy: .public):\(line, privacy: .public):\t\(message, privacy: .public)"
            )
        #else
            logger.error("\(fileID):\(line):\t\(message)")
        #endif
    }
}

extension OSLogEntryLog.Level {
    // periphery: ignore
    public var description: String {
        switch self {
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .error:
            return "ERROR"
        default:
            return ""
        }
    }
}
