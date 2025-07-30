import Foundation

struct CStringArray {
    let data: UnsafePointer<UnsafeMutablePointer<CChar>?>
    let len: CInt
}

// periphery: ignore
@_silgen_name("ffi_git_clone")
func ffi_git_clone(
    _ url: UnsafePointer<CChar>,
    into: UnsafePointer<CChar>
) -> CInt

// periphery: ignore
@_silgen_name("ffi_git_reset")
func ffi_git_reset(_ repo: UnsafePointer<CChar>) -> CInt

// periphery: ignore
@_silgen_name("ffi_git_config_set_user")
func ffi_git_config_set_user(
    _ repo: UnsafePointer<CChar>,
    username: UnsafePointer<CChar>
) -> CInt

// periphery: ignore
@_silgen_name("ffi_git_stage")
func ffi_git_stage(
    _ repo: UnsafePointer<CChar>,
    relativePath: UnsafePointer<CChar>
) -> CInt

// periphery: ignore
@_silgen_name("ffi_git_commit")
func ffi_git_commit(
    _ repo: UnsafePointer<CChar>,
    message: UnsafePointer<CChar>
) -> CInt

// periphery: ignore
@_silgen_name("ffi_git_push")
func ffi_git_push(_ repo: UnsafePointer<CChar>) -> CInt

// periphery: ignore
@_silgen_name("ffi_git_local_head_matches_remote")
func ffi_git_local_head_matches_remote(_ repo: UnsafePointer<CChar>) -> CInt

// periphery: ignore
@_silgen_name("ffi_git_log")
func ffi_git_log(_ repo: UnsafePointer<CChar>) -> CStringArray

@_silgen_name("ffi_git_strerror")
func ffi_git_strerror() -> UnsafeMutablePointer<CChar>?

////////////////////////////////////////////////////////////////////////////////

private let repo = GIT_DIR

enum Git {
    /// Stage and commit a new file or folder
    static func addCommit(node: PwNode, nodeIsNew: Bool) throws {
        try Git.stage(relativePath: node.relativePath)
        try Git.commit(
            message:
                "\(nodeIsNew ? "Added" : "Changed") \(node.relativePathNoExtension)"
        )
    }

    /// Remove a file or folder and create a commit with the change
    static func rmCommit(node: PwNode) throws {
        try FileManager.default.removeItem(atPath: node.path.string)
        try Git.stage(relativePath: node.relativePath)
        try Git.commit(message: "Deleted \(node.relativePathNoExtension)")
    }

    /// Move a file or folder and create a commit with the change
    static func mvCommit(fromNode: PwNode, toNode: PwNode) throws {
        try FileManager.default.moveItem(
            atPath: fromNode.path.string,
            toPath: toNode.path.string)

        try Git.stage(relativePath: fromNode.relativePath)
        try Git.stage(relativePath: toNode.relativePath)

        let msg =
            "Renamed \(fromNode.relativePathNoExtension) to \(toNode.relativePathNoExtension)"
        try Git.commit(message: msg)
    }

    static func clone(remote: String) throws {
        let repoC = try repo.string.toCString()
        let urlC = try remote.toCString()

        LOG.debug("Cloning from: \(remote)")

        let r = ffi_git_clone(urlC, into: repoC)
        if r != 0 {
            try throwError(code: r)
        }
    }

    static func push() throws {
        let repoC = try repo.string.toCString()
        let r = ffi_git_push(repoC)
        if r != 0 {
            try throwError(code: r)
        }
        LOG.debug("Push successful")
    }

    static func localHeadMatchesRemote() throws -> Bool {
        let repoC = try repo.string.toCString()
        let r = ffi_git_local_head_matches_remote(repoC)
        if r != 0 && r != 1 {
            try throwError(code: r)
        }
        return r == 1
    }

    static func reset() throws {
        LOG.warning("Resetting to local HEAD")
        let repoC = try repo.string.toCString()
        let r = ffi_git_reset(repoC)
        if r != 0 {
            try throwError(code: r)
        }
    }

    static func configSetUser(username: String) throws {
        let repoC = try repo.string.toCString()
        let usernameC = try username.toCString()
        let r = ffi_git_config_set_user(repoC, username: usernameC)
        if r != 0 {
            try throwError(code: r)
        }
    }

    static func log() throws -> [CommitInfo] {
        LOG.debug("Fetching commit messages")
        var messages = [CommitInfo]()

        let repoC = try repo.string.toCString()
        let arr = ffi_git_log(repoC)
        if arr.len < 0 {
            try throwError(code: arr.len)
        }

        for i in 0..<Int(arr.len) {
            if let cString = arr.data[i] {

                let str = String(cString: cString)
                ffi_free_cstring(cString)

                let commitInfo = try CommitInfo.from(str)
                messages.append(commitInfo)
            }
        }

        return messages
    }

    static func repoIsInitialized() -> Bool {
        let idents = GIT_DIR.appending(".age-identities")
        let recips = GIT_DIR.appending(".age-recipients")
        return FileManager.default.isFile(idents)
            && FileManager.default.isFile(recips)
    }

    static private func commit(message: String) throws {
        let repoC = try repo.string.toCString()
        let messageC = try message.toCString()

        let r = ffi_git_commit(repoC, message: messageC)
        if r != 0 {
            try throwError(code: r)
        }
    }

    static private func stage(relativePath: String) throws {
        let repoC = try repo.string.toCString()
        let relativePathC = try relativePath.toCString()

        let r = ffi_git_stage(repoC, relativePath: relativePathC)
        if r != 0 {
            try throwError(code: r)
        }
        LOG.debug("Staged '\(relativePath)'")
    }

    static private func throwError(code: CInt) throws {
        let s = ffi_git_strerror()
        guard let s else {
            throw AppError.gitError("code \(code)")
        }

        let msg = String(cString: s)
        ffi_free_cstring(s)

        throw AppError.gitError(msg)
    }
}
