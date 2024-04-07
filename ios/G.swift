import Foundation
import OSLog
import UIKit
import SwiftUI

/// Global constants
enum G {
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                        category: "generic")

    static let rootNodeName = "/"
    static let gitDirName = "git"
    static let gitDir = FileManager.default.appDataDirectory.appending(path: G.gitDirName)

    static let ageDecryptOutSize: CInt = 2048

    static let screenWidth = UIScreen.main.bounds.size.width
    static let screenHeight = UIScreen.main.bounds.size.height

    static let textColor = Color(UIColor.label)
}
