import Foundation
import OSLog
import SwiftUI
import UIKit

/// Global constants
enum G {
    static let logger = DeviceLogger()

    static let rootNodeName = "/"
    static let gitDirName = "git-adc83b19e"
    static let gitDir = FileManager.default.appDataDirectory.appending(
        path: G.gitDirName)

    static let ageDecryptOutSize: CInt = 2048

    static let screenWidth = UIScreen.main.bounds.size.width
    static let screenHeight = UIScreen.main.bounds.size.height

    static let textColor = Color(UIColor.label)
    static let textFieldBgColor = Color(UIColor.tertiarySystemFill)

    static let headerFont = Font.system(size: 20)
    static let errorColor = Color(UIColor(named: "ErrorColor")!)

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
