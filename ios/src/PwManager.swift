import Foundation

enum PwManager {
    // Submit the selected parameters and create/modify the password tree to
    // contain the new node.
    static func submit(
        selectedName: String,
        selectedRelativePath: String,
        selectedDirectory: Bool,
        currentPwNode: PwNode?,
        password: String,
        generate: Bool = false
    ) throws -> PwNode {
        if selectedName == "otp" {
            // The "otp" name has special handling, these entries should not be
            // added or edited within the app.
            throw AppError.invalidNodePath("The name 'otp' is reserved")
        }

        // Selected name is only allowed to be taken if it is equal to the currentPwNode
        let selectedPath = PwNode.createAbsPath(
            name: selectedName,
            relativePath: selectedRelativePath,
            expectPassword: !selectedDirectory)
        let allowNameTaken = selectedPath == currentPwNode?.path

        // The `newPwNode` and `currentPwNode` are equal if we are modifying an existing node
        let newPwNode = try PwNode.loadValidatedFrom(
            name: selectedName,
            relativePath: selectedRelativePath,
            expectPassword: !selectedDirectory,
            checkParents: true,
            allowNameTaken: allowNameTaken)

        if let currentPwNode {
            if currentPwNode.isPassword {
                try PwManager.changePasswordNode(
                    currentPwNode: currentPwNode,
                    newPwNode: newPwNode,
                    password: password)
            }
            else {
                try PwManager.renameFolder(
                    currentPwNode: currentPwNode,
                    newPwNode: newPwNode)
            }
        }
        else {
            if selectedDirectory {
                try PwManager.addFolder(newPwNode: newPwNode)
            }
            else {
                try PwManager.addPassword(
                    newPwNode: newPwNode, password: password,
                    generate: generate)
            }
        }

        return newPwNode
    }

    /// Remove the provided node from the tree
    static func remove(node: PwNode) throws {
        if !node.isPassword {
            if (try? FileManager.default.findFirstFile(node.path)) == nil {
                // Remove the node without creating a commit if there are no
                // files beneath it
                try FileManager.default.removeItem(atPath: node.path.string)
                return
            }
        }
        try Git.rmCommit(node: node)
    }

    private static func addFolder(newPwNode: PwNode) throws {
        try FileManager.default.createDirectory(
            atPath: newPwNode.path.string,
            withIntermediateDirectories: false)
    }

    private static func renameFolder(
        currentPwNode: PwNode,
        newPwNode: PwNode
    ) throws {
        if (try? FileManager.default.findFirstFile(currentPwNode.path)) == nil {
            // Move the node without creating a commit if there are no
            // files beneath it
            try FileManager.default.moveItem(
                atPath: currentPwNode.path.string,
                toPath: newPwNode.path.string)
            return
        }
        try Git.mvCommit(fromNode: currentPwNode, toNode: newPwNode)
    }

    /// Replace the `currentPwNode` with `newPwNode`, one commit is created for
    /// moving the password, one commit is created for changing its value.
    private static func changePasswordNode(
        currentPwNode: PwNode,
        newPwNode: PwNode,
        password: String
    ) throws {
        // Move the password node if the current and new node are different
        if newPwNode.path != currentPwNode.path {
            try Git.mvCommit(fromNode: currentPwNode, toNode: newPwNode)
        }

        // Update the password if one was provided
        if !password.isEmpty {
            try checkPassword(password: password)
            let recipientPath = GIT_DIR.appending(".age-recipients")

            try Age.encrypt(
                recipientPath: recipientPath,
                outPath: newPwNode.path,
                plaintext: password)

            try Git.addCommit(node: newPwNode, nodeIsNew: false)
        }
    }

    private static func addPassword(
        newPwNode: PwNode, password: String,
        generate: Bool
    ) throws {
        if !generate {
            try checkPassword(password: password)
        }

        let recipientPath = GIT_DIR.appending(".age-recipients")
        let plaintext = generate ? randomString(20) : password

        try Age.encrypt(
            recipientPath: recipientPath,
            outPath: newPwNode.path,
            plaintext: plaintext)

        try Git.addCommit(node: newPwNode, nodeIsNew: true)
    }

    private static func checkPassword(password: String) throws {
        if password.count > MAX_PASSWORD_LENGTH || password.isEmpty {
            throw AppError.invalidPasswordFormat
        }
    }

    private static func randomString(_ length: Int) -> String {
        return String(
            (0..<length).map { _ in
                "\"!#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
                    .randomElement()!
            })
    }
}
