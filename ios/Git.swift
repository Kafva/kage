import Foundation

struct Git {
    static let repo = G.gitDir

    static func clone(remote: String) {
        do {
            let repoC = try repo.path().toCString()
            let urlC = try remote.toCString()

            G.logger.debug("Cloning from: \(remote)")
            let r = ffi_git_clone(urlC, into: repoC);
            if r != 0 {
                G.logger.error("git clone failed: \(r)")
                return
            }
            G.logger.debug("git clone OK")

        } catch {
            G.logger.error("\(error)")
        }
    }

    static func commit(message: String) -> Bool {
        do {
            let repoC = try repo.path().toCString()
            let messageC = try message.toCString()

            return ffi_git_commit(repoC, message: messageC) == 0
        } catch {
            G.logger.error("\(error)")
        }

        return false
    }

    static func add(relativePath: String) -> Bool {
        do {
            let repoC = try repo.path().toCString()
            let relativePathC = try relativePath.toCString()

            return ffi_git_add(repoC, relativePath: relativePathC) == 0
        } catch {
            G.logger.error("\(error)")
        }

        return false
    }

    static func pull() -> Bool {
        do {
            let repoC = try repo.path().toCString()
            return ffi_git_pull(repoC) == 0

        } catch {
            G.logger.error("\(error)")
        }

        return false
    }

    static func push() -> Bool {
        do {
            let repoC = try repo.path().toCString()
            return ffi_git_push(repoC) == 0

        } catch {
            G.logger.error("\(error)")
        }

        return false
    }

    static func indexHasLocalChanges() -> Bool {
        do {
            let repoC = try repo.path().toCString()
            return ffi_git_index_has_local_changes(repoC) == 1

        } catch {
            G.logger.error("\(error)")
        }

        return false
    }
}
