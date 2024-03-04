import Foundation
import OSLog

let LOGGER = Logger(subsystem: Bundle.main.bundleIdentifier!,
                    category: "generic")

let GIT_DIR = FileManager.default.appDataDirectory.appending(path: "git")

let AGE_DECRYPT_OUT_SIZE: CInt = 2048

