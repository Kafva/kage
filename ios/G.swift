import Foundation
import OSLog

/// Global constants
struct G {
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                        category: "generic")

    static let gitDir = FileManager.default.appDataDirectory.appending(path: "git")

    static let ageDecryptOutSize: CInt = 2048
}
