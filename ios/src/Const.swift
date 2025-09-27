import Foundation
import SwiftUI
import System
import UIKit

let ROOT_NODE_NAME = "/"
let GIT_DIR_NAME = "git-adc83b19e"
let GIT_DIR: FilePath = FileManager.default.appDataDirectory
    .appending(GIT_DIR_NAME)

let MAX_TREE_DEPTH: Int = 15
let MAX_PASSWORD_LENGTH: Int = 1024
let AUTO_LOCK_SECONDS: TimeInterval = 120.0

let TEXT_COLOR = Color(UIColor.label)
let TEXT_FIELD_BG_COLOR = Color(UIColor.tertiarySystemFill)

// Fixed versions of the builtin font sizes
// https://developer.apple.com/design/human-interface-guidelines/typography
let TITLE2_FONT = Font.system(size: 22.0)
let TITLE3_FONT = Font.system(size: 20.0)
let BODY_FONT = Font.system(size: 17.0)
let FOOTNOTE_FONT = Font.system(size: 14.0)
let CAPTION_FONT = Font.system(size: 12.0)

let TOOLBAR_ICON_FONT = Font.system(size: 24.0).bold()

// Defined in: Assets.xcassets
let ERROR_COLOR = Color(UIColor(named: "ErrorColor")!)
let ACCENT_COLOR = Color(UIColor(named: "AccentColor")!)

var GIT_VERSION: String {
    let version =
        Bundle.main.infoDictionary?["GitVersion"] as? String
        ?? "Unknown"
    #if DEBUG
        return "\(version) (debug)"
    #else
        return "\(version) (release)"
    #endif
}
