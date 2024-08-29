import Foundation

enum PwManager {
    // Submit the `newPwNode` and create/modify the password tree to contain the new node.
    static func submit(
        currentPwNode: PwNode?, newPwNode: PwNode, directorySelected: Bool,
        password: String, confirmPassword: String, generate: Bool
    ) throws {
        if let currentPwNode {
            if currentPwNode.isPassword {
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
        if !node.isPassword {
            if (try? FileManager.default.findFirstFile(node.url)) == nil {
                // Remove the node without creating a commit if there are no
                // files beneath it
                try FileManager.default.removeItem(at: node.url)
                return
            }
        }
        try Git.rmCommit(node: node)
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
        if (try? FileManager.default.findFirstFile(currentPwNode.url)) == nil {
            // Move the node without creating a commit if there are no
            // files beneath it
            try FileManager.default.moveItem(
                at: currentPwNode.url, to: newPwNode.url)
            return
        }
        try Git.mvCommit(fromNode: currentPwNode, toNode: newPwNode)
    }

    /// Replace the `currentPwNode` with `newPwNode`, one commit is created for
    /// moving the password, one commit is created for changing its value.
    private static func changePasswordNode(
        currentPwNode: PwNode,
        newPwNode: PwNode,
        password: String,
        confirmPassword: String
    ) throws {
        // Move the password node if the current and new node are different
        if newPwNode.url != currentPwNode.url {
            try Git.mvCommit(fromNode: currentPwNode, toNode: newPwNode)
        }

        // Update the password if one was provided
        if !password.isEmpty {
            try checkPassword(
                password: password, confirmPassword: confirmPassword)
            let recipient = G.gitDir.appending(path: ".age-recipients")

            try Age.encrypt(
                recipient: recipient,
                outpath: newPwNode.url,
                plaintext: password)

            try Git.addCommit(node: newPwNode, nodeIsNew: false)
        }
    }

    private static func addPassword(
        newPwNode: PwNode, password: String,
        confirmPassword: String, generate: Bool
    ) throws {
        if !generate {
            try checkPassword(
                password: password, confirmPassword: confirmPassword)
        }

        let recipient = G.gitDir.appending(path: ".age-recipients")
        let plaintext = generate ? String.random(18) : password

        try Age.encrypt(
            recipient: recipient,
            outpath: newPwNode.url,
            plaintext: plaintext)

        try Git.addCommit(node: newPwNode, nodeIsNew: true)
    }

    private static func checkPassword(
        password: String, confirmPassword: String
    ) throws {
        if password.count > G.maxPasswordLength || password.isEmpty
            || !password.isContiguousUTF8
        {
            throw AppError.invalidPasswordFormat
        }

        if password != confirmPassword {
            throw AppError.passwordMismatch
        }
    }
}
