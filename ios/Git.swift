import Foundation

struct Git {
    static func clone(remote: String, into: URL) {
        do {
            let intoC = try into.path().toCString()
            let urlC = try remote.toCString()

            LOGGER.debug("Cloning from: \(remote)")
            let r = ffi_git_clone(urlC, into: intoC);
            if r != 0 {
                LOGGER.error("git clone failed: \(r)")
                return
            }
            LOGGER.debug("git clone OK")

        } catch {
            LOGGER.error("\(error)")
        }
    }

    static func commit(_ repo: URL, message: String) -> Bool {
        do {
            let repoC = try repo.path().toCString()
            let messageC = try message.toCString()

            return ffi_git_commit(repoC, message: messageC) == 0
        } catch {
            LOGGER.error("\(error)")
        }

        return false
    }

    static func add(_ repo: URL, relativePath: String) -> Bool {
        do {
            let repoC = try repo.path().toCString()
            let relativePathC = try relativePath.toCString()

            return ffi_git_add(repoC, relativePath: relativePathC) == 0
        } catch {
            LOGGER.error("\(error)")
        }

        return false
    }

    static func pull(_ repo: URL) -> Bool {
        do {
            let repoC = try repo.path().toCString()
            return ffi_git_pull(repoC) == 0

        } catch {
            LOGGER.error("\(error)")
        }

        return false
    }

    static func push(_ repo: URL) -> Bool {
        do {
            let repoC = try repo.path().toCString()
            return ffi_git_push(repoC) == 0

        } catch {
            LOGGER.error("\(error)")
        }

        return false
    }
}
