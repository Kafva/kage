import Foundation

struct Git {
    static func clone(remote: String, into: URL) {
        try? FileManager.default.removeItem(at: into)

        do {
            let intoC = try into.path().toCString()
            let urlC = try remote.toCString()

            logger.debug("Cloning from: \(remote)")
            let r = ffi_git_clone(urlC, into: intoC);
            if r != 0 {
                logger.error("git clone failed: \(r)")
                return
            }
            logger.debug("git clone OK")

        } catch {
            logger.error("\(error)")
        }
    }

    static func commit(_ repo: URL, message: String) -> Bool {
        do {
            let repoC = try repo.path().toCString()
            let messageC = try message.toCString()

            return ffi_git_commit(repoC, message: messageC) == 0
        } catch {
            logger.error("\(error)")
        }

        return false
    }

    static func add(_ repo: URL, relativePath: String) -> Bool {
        do {
            let repoC = try repo.path().toCString()
            let relativePathC = try relativePath.toCString()

            return ffi_git_add(repoC, relativePath: relativePathC) == 0
        } catch {
            logger.error("\(error)")
        }

        return false
    }

    static func pull(_ repo: URL) {

    }

    static func push(_ repo: URL) {

    }
}
