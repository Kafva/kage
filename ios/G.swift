import Foundation
import OSLog
import UIKit

/// Global constants
struct G {
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                        category: "generic")

    static let gitDir = FileManager.default.appDataDirectory.appending(path: "git")

    static let ageDecryptOutSize: CInt = 2048

    static let screenWidth = UIScreen.main.bounds.size.width
    static let screenHeight = UIScreen.main.bounds.size.height
}

func guardLet<T>(_ value: T?, _ error: Error) throws -> T {
    guard let unwrappedValue = value else {
        throw error
    }
    return unwrappedValue
}

