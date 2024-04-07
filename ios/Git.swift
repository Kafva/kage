import Foundation

@_silgen_name("ffi_git_clone")
func ffi_git_clone(_ url: UnsafePointer<CChar>,
                          into: UnsafePointer<CChar>) -> CInt
@_silgen_name("ffi_git_reset")
func ffi_git_reset(_ repo: UnsafePointer<CChar>) -> CInt

@_silgen_name("ffi_git_config_set_user")
func ffi_git_config_set_user(_ repo: UnsafePointer<CChar>, 
                        username: UnsafePointer<CChar>) -> CInt

@_silgen_name("ffi_git_stage")
func ffi_git_stage(_ repo: UnsafePointer<CChar>,
                          relativePath: UnsafePointer<CChar>,
                          add: Bool) -> CInt

@_silgen_name("ffi_git_commit")
func ffi_git_commit(_ repo: UnsafePointer<CChar>,
                           message: UnsafePointer<CChar>) -> CInt

@_silgen_name("ffi_git_pull")
func ffi_git_pull(_ repo: UnsafePointer<CChar>) -> CInt

@_silgen_name("ffi_git_push")
func ffi_git_push(_ repo: UnsafePointer<CChar>) -> CInt

@_silgen_name("ffi_git_index_has_local_changes")
func ffi_git_index_has_local_changes(_ repo: UnsafePointer<CChar>) -> CInt

////////////////////////////////////////////////////////////////////////////////

private let repo = G.gitDir

enum Git {
    static func addCommit(node: PwNode) throws {
        try Git.stage(relativePath: node.relativePath, add: true)
        try Git.commit(message: "Added '\(node.relativePath)'")
    }

    static func rmCommit(node: PwNode) throws {
        try Git.stage(relativePath: node.relativePath, add: false)
        try FileManager.default.removeItem(at: node.url)
        try Git.commit(message: "Deleted '\(node.relativePath)'")
    }

    static func clone(remote: String) throws {
        let repoC = try repo.path().toCString()
        let urlC = try remote.toCString()

        G.logger.debug("Cloning from: \(remote)")

        let r = ffi_git_clone(urlC, into: repoC);
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

    static func reset() throws {
        G.logger.warning("Resetting to remote HEAD")
        let repoC = try repo.path().toCString()
        let r = ffi_git_reset(repoC)
        if r != 0 {
            throw AppError.gitError(r)
        }
    }

    static func configSetUser(username: String) throws {
        let repoC = try repo.path().toCString()
        let usernameC = try username.toCString()
        let r = ffi_git_config_set_user(repoC, username: usernameC)
        if r != 0 {
            throw AppError.gitError(r)
        }
    }

    static private func commit(message: String) throws {
        let repoC = try repo.path().toCString()
        let messageC = try message.toCString()

        let r = ffi_git_commit(repoC, message: messageC)
        if r != 0 {
            throw AppError.gitError(r)
        }
    }

    static private func stage(relativePath: String, add: Bool) throws {
        let repoC = try repo.path().toCString()
        let relativePathC = try relativePath.toCString()

        G.logger.debug("\(add ? "Adding" : "Removing") '\(relativePath)'")
        let r = ffi_git_stage(repoC, relativePath: relativePathC, add: add)
        if r != 0 {
            throw AppError.gitError(r)
        }
    }
}
