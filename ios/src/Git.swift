import Foundation

@_silgen_name("ffi_git_clone")
func ffi_git_clone(
    _ url: UnsafePointer<CChar>,
    into: UnsafePointer<CChar>
) -> CInt
@_silgen_name("ffi_git_reset")
func ffi_git_reset(_ repo: UnsafePointer<CChar>) -> CInt

@_silgen_name("ffi_git_config_set_user")
func ffi_git_config_set_user(
    _ repo: UnsafePointer<CChar>,
    username: UnsafePointer<CChar>
) -> CInt

@_silgen_name("ffi_git_stage")
func ffi_git_stage(
    _ repo: UnsafePointer<CChar>,
    relativePath: UnsafePointer<CChar>
) -> CInt

@_silgen_name("ffi_git_commit")
func ffi_git_commit(
    _ repo: UnsafePointer<CChar>,
    message: UnsafePointer<CChar>
) -> CInt

@_silgen_name("ffi_git_pull")
func ffi_git_pull(_ repo: UnsafePointer<CChar>) -> CInt

@_silgen_name("ffi_git_push")
func ffi_git_push(_ repo: UnsafePointer<CChar>) -> CInt

@_silgen_name("ffi_git_index_has_local_changes")
func ffi_git_index_has_local_changes(_ repo: UnsafePointer<CChar>) -> CInt

@_silgen_name("ffi_git_strerror")
func ffi_git_strerror(code: CInt) -> UnsafeMutablePointer<CChar>?

////////////////////////////////////////////////////////////////////////////////

private let repo = G.gitDir

enum Git {
    /// Stage and commit a new file or folder
    static func addCommit(node: PwNode, nodeIsNew: Bool) throws {
        try Git.stage(relativePath: node.relativePath)
        try Git.commit(
            message: "\(nodeIsNew ? "Added" : "Changed") '\(node.relativePath)'"
        )
    }

    /// Remove a file or folder and create a commit with the change
    static func rmCommit(node: PwNode) throws {
        try FileManager.default.removeItem(at: node.url)
        try Git.stage(relativePath: node.relativePath)
        try Git.commit(message: "Deleted '\(node.relativePath)'")
    }

    /// Move a file or folder and create a commit with the change
    static func mvCommit(fromNode: PwNode, toNode: PwNode) throws {
        try FileManager.default.moveItem(
            at: fromNode.url,
            to: toNode.url)

        try Git.stage(relativePath: fromNode.relativePath)
        try Git.stage(relativePath: toNode.relativePath)

        let msg =
            "Renamed '\(fromNode.relativePath)' to '\(toNode.relativePath)'"
        try Git.commit(message: msg)
    }

    static func clone(remote: String) throws {
        let repoC = try repo.path().toCString()
        let urlC = try remote.toCString()

        G.logger.debug("Cloning from: \(remote)")

        let r = ffi_git_clone(urlC, into: repoC)
        if r != 0 {
            try throwError(code: r)
        }
    }

    static func pull() throws {
        let repoC = try repo.path().toCString()
        let r = ffi_git_pull(repoC)
        if r != 0 {
            try throwError(code: r)
        }
        G.logger.debug("Pull successful")
    }

    static func push() throws {
        let repoC = try repo.path().toCString()
        let r = ffi_git_push(repoC)
        if r != 0 {
            try throwError(code: r)
        }
        G.logger.debug("Push successful")
    }

    static func indexHasLocalChanges() throws -> Bool {
        let repoC = try repo.path().toCString()
        let r = ffi_git_index_has_local_changes(repoC)
        if r != 0 && r != 1 {
            try throwError(code: r)
        }
        return r == 1
    }

    static func reset() throws {
        G.logger.warning("Resetting to remote HEAD")
        let repoC = try repo.path().toCString()
        let r = ffi_git_reset(repoC)
        if r != 0 {
            try throwError(code: r)
        }
    }

    static func configSetUser(username: String) throws {
        let repoC = try repo.path().toCString()
        let usernameC = try username.toCString()
        let r = ffi_git_config_set_user(repoC, username: usernameC)
        if r != 0 {
            try throwError(code: r)
        }
    }

    static func repoIsEmpty() -> Bool {
        return (try? FileManager.default.findFirstFile(repo) == nil) ?? true
    }

    static private func commit(message: String) throws {
        let repoC = try repo.path().toCString()
        let messageC = try message.toCString()

        let r = ffi_git_commit(repoC, message: messageC)
        if r != 0 {
            try throwError(code: r)
        }
    }

    static private func stage(relativePath: String) throws {
        let repoC = try repo.path().toCString()
        let relativePathC = try relativePath.toCString()

        let r = ffi_git_stage(repoC, relativePath: relativePathC)
        if r != 0 {
            try throwError(code: r)
        }
        G.logger.debug("Staged '\(relativePath)'")
    }

    static private func throwError(code: CInt) throws {
        let s = ffi_git_strerror(code: code)
        guard let s else {
            throw AppError.gitError("No description")
        }

        let msg = String(cString: s)
        ffi_free_cstring(s)

        throw AppError.gitError(msg)
    }
}
