import Foundation

struct Git {
    static func clone(remote: String, into: URL) {
        try? FileManager.default.removeItem(at: into)

        let intoC = into.path().cString(using: .utf8)!
        let urlC = remote.cString(using: .utf8)!

        logger.debug("Cloning from: \(remote)")
        let r = ffi_git_clone(url: urlC, into: intoC);
        if r != 0 {
            logger.error("git clone failed: \(r)")
            return
        }
        logger.debug("git clone OK")
    }
}
