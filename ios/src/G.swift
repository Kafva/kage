import Foundation
import SwiftUI
import System
import UIKit

/// Global constants
enum G {
    static let logger = DeviceLogger()

    static let rootNodeName = "/"
    static let gitDirName = "git-adc83b19e"
    static let gitDir: FilePath = FileManager.default.appDataDirectory
        .appending(G.gitDirName)

    static let maxTreeDepth: Int = 15
    static let maxPasswordLength: Int = 1024
    static let autoLockSeconds: TimeInterval = 120.0
    static let screenWidth = UIScreen.main.bounds.size.width
    static let screenHeight = UIScreen.main.bounds.size.height

    static let textColor = Color(UIColor.label)
    static let textFieldBgColor = Color(UIColor.tertiarySystemFill)

    // Fixed versions of the builtin font sizes
    // https://developer.apple.com/design/human-interface-guidelines/typography
    static let title2Font = Font.system(size: 22.0)
    static let title3Font = Font.system(size: 20.0)
    static let bodyFont = Font.system(size: 17.0)
    static let footnoteFont = Font.system(size: 14.0)
    static let captionFont = Font.system(size: 12.0)

    static let toolbarIconFont = Font.system(size: 24.0).bold()

    // Defined in: Assets.xcassets
    static let errorColor = Color(UIColor(named: "ErrorColor")!)
    static let accentColor = Color(UIColor(named: "AccentColor")!)

    static var gitVersion: String {
        let version =
            Bundle.main.infoDictionary?["GitVersion"] as? String
            ?? "Unknown"
        #if DEBUG
            return "\(version) (debug)"
        #else
            return "\(version) (release)"
        #endif
    }

}
