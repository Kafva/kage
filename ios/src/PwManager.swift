import Foundation

enum PwManager {
    // Submit the `newPwNode` and create/modify the password tree to contain the new node.
    static func submit(
        currentPwNode: PwNode?, newPwNode: PwNode, directorySelected: Bool,
        password: String, confirmPassword: String, generate: Bool
    ) throws {
        if let currentPwNode {
            if currentPwNode.isDir {
                try PwManager.changePasswordNode(
                    currentPwNode: currentPwNode,
                    newPwNode: newPwNode,
                    password: password,
                    confirmPassword: confirmPassword)
            }
            else {
                try PwManager.renameFolder(
                    currentPwNode: currentPwNode,
                    newPwNode: newPwNode)
            }
        }
        else {
            if try newPwNode.nameTaken() {
                throw AppError.invalidNodePath(
                    "Path already taken: '\(newPwNode.relativePath)'")
            }
            if directorySelected {
                try PwManager.addFolder(newPwNode: newPwNode)
            }
            else {
                try PwManager.addPassword(
                    newPwNode: newPwNode, password: password,
                    confirmPassword: confirmPassword, generate: generate)
            }
        }
    }

    /// Remove the provided node from the tree
    static func remove(node: PwNode) throws {
        if try FileManager.default.findFirstFile(node.url) == nil {
            // Just remove the node if there are no files beneath it
            try FileManager.default.removeItem(at: node.url)
        }
        else {
            try Git.rmCommit(node: node)
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
        // TODO handle empty folders
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
        try checkPassword(password: password, confirmPassword: confirmPassword)

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
        try checkPassword(
            password: password, confirmPassword: confirmPassword,
            generate: generate)

        let recipient = G.gitDir.appending(path: ".age-recipients")
        let plaintext = generate ? String.random(18) : password

        try Age.encrypt(
            recipient: recipient,
            outpath: newPwNode.url,
            plaintext: plaintext)

        try Git.addCommit(node: newPwNode, nodeIsNew: true)
    }

    private static func checkPassword(
        password: String, confirmPassword: String, generate: Bool = false
    ) throws {
        if password.count > G.maxPasswordLength || password.isEmpty
            || !password.isContiguousUTF8
        {
            throw AppError.invalidPasswordFormat
        }

        if !generate && password != confirmPassword {
            throw AppError.passwordMismatch
        }
    }
}
