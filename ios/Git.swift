import Foundation

struct Git {
    static let repo = G.gitDir

    static func clone(remote: String) throws {
        let repoC = try repo.path().toCString()
        let urlC = try remote.toCString()

        G.logger.debug("Cloning from: \(remote)")

        let r = ffi_git_clone(urlC, into: repoC);
        if r != 0 {
            throw AppError.gitError(r)
        }
    }

    static func commit(message: String) throws {
        let repoC = try repo.path().toCString()
        let messageC = try message.toCString()

        let r = ffi_git_commit(repoC, message: messageC)
        if r != 0 {
            throw AppError.gitError(r)
        }
    }

    static func stage(relativePath: String, add: Bool) throws {
        let repoC = try repo.path().toCString()
        let relativePathC = try relativePath.toCString()

        G.logger.debug("\(add ? "Adding" : "Removing") '\(relativePath)'")
        let r = ffi_git_stage(repoC, relativePath: relativePathC, add: add)
        if r != 0 {
            throw AppError.gitError(r)
        }
    }

    static func pull() throws {
        let repoC = try repo.path().toCString()
        let r = ffi_git_pull(repoC)
        if r != 0 {
            throw AppError.gitError(r)
        }
    }

    static func push() throws {
        let repoC = try repo.path().toCString()
        let r = ffi_git_push(repoC)
        if r != 0 {
            throw AppError.gitError(r)
        }
    }

    static func indexHasLocalChanges() throws -> Bool {
        let repoC = try repo.path().toCString()
        let r = ffi_git_index_has_local_changes(repoC)
        if r != 0 && r != 1 {
            throw AppError.gitError(r)
        }
        return r == 1
    }
}
