import Foundation

enum PwManager {
    // Submit the `newPwNode` and create/modify the password tree to contain the new node.
    static func submit(
        currentPwNode: PwNode?, newPwNode: PwNode, isDir: Bool,
        password: String, confirmPassword: String, generate: Bool
    ) throws {
        if let currentPwNode, !currentPwNode.isDir {
            try PwManager.changePasswordNode(
                currentPwNode: currentPwNode,
                newPwNode: newPwNode,
                password: password,
                confirmPassword: confirmPassword)

        }
        else if let currentPwNode, currentPwNode.isDir {
            try PwManager.renameFolder(
                currentPwNode: currentPwNode,
                newPwNode: newPwNode)
        }
        else if isDir {
            try PwManager.addFolder(newPwNode: newPwNode)
        }
        else {
            try PwManager.addPassword(
                newPwNode: newPwNode, password: password,
                confirmPassword: confirmPassword, generate: generate)
        }
    }

    private static func addFolder(newPwNode: PwNode) throws {
        try FileManager.default.createDirectory(
            at: newPwNode.url,
            withIntermediateDirectories: false)
    }

    private static func renameFolder(
        currentPwNode: PwNode,
        newPwNode: PwNode
    ) throws {
        try Git.mvCommit(fromNode: currentPwNode, toNode: newPwNode)
    }

    /// Replace the `currentPwNode` with `newPwNode`, one commit is created for
    /// moving the password, one commit is created for changing its value.
    private static func changePasswordNode(
        currentPwNode: PwNode,
        newPwNode: PwNode?,
        password: String,
        confirmPassword: String
    ) throws {
        if !password.isEmpty && password != confirmPassword {
            throw AppError.passwordMismatch
        }

        // Select the new node if it will be moved, otherwise use the selected node
        let pwNode = newPwNode ?? currentPwNode
        // Move the password node if the current and new node are different
        let nodePathUnchanged = pwNode.url == currentPwNode.url
        if let newPwNode, !nodePathUnchanged {
            try Git.mvCommit(fromNode: currentPwNode, toNode: newPwNode)
        }

        let recipient = G.gitDir.appending(path: ".age-recipients")

        try Age.encrypt(
            recipient: recipient,
            outpath: pwNode.url,
            plaintext: password)

        try Git.addCommit(node: pwNode, nodeIsNew: !nodePathUnchanged)
    }

    private static func addPassword(
        newPwNode: PwNode, password: String,
        confirmPassword: String, generate: Bool
    ) throws {
        if !generate && (password.isEmpty || password != confirmPassword) {
            throw AppError.passwordMismatch
        }

        let recipient = G.gitDir.appending(path: ".age-recipients")
        let plaintext = generate ? String.random(18) : password

        try Age.encrypt(
            recipient: recipient,
            outpath: newPwNode.url,
            plaintext: plaintext)

        try Git.addCommit(node: newPwNode, nodeIsNew: true)
    }
}
