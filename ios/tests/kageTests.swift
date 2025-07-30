import SwiftUI
import Testing

@testable import kage

/// Expected passphrase for the test data
let PASSPHRASE = "x"
let REMOTE = "git://127.0.0.1/ios.git"
let USERNAME = "ios"

let INVALID_NODE_PATH_ERROR = AppError.invalidNodePath("")
    .localizedDescription

/// The testcases can not run in parallel, use `.serialized`
@Suite(.serialized)
final class KageTests {
    var appState: AppState

    /// Setup to run before each test method
    init() throws {
        print("Running setup...")
        try? FileManager.default.removeItem(atPath: GIT_DIR.string)
        do {
            try Git.clone(remote: REMOTE)
        }
        catch {
            Issue.record("\(error.localizedDescription)")
        }

        // (Re-)initialise app state and reset
        self.appState = AppState()
        try Git.configSetUser(username: USERNAME)
        try Git.reset()
        try appState.reloadGitTree()
    }

    /// Teardown to run after each test
    deinit {
        print("Running teardown...")
        // Each test case expects that it starts out being up-to-date
        do {
            try Git.push()
        }
        catch {
            print("Failed to push on exit: \(error.localizedDescription)")
        }
    }

    /// Add a new password and push it to the remote
    @Test func addPassword() throws {
        let name = getTestcaseNodeName()
        let password = getTestcasePassword()
        do {
            let newPwNode = try PwManager.submit(
                selectedName: name,
                selectedRelativePath: "/",
                selectedDirectory: false,
                currentPwNode: nil,
                password: password)

            // Reload git tree with new entry
            try appState.reloadGitTree()

            // There should be a change between our local repo and the remote
            #expect(!appState.localHeadMatchesRemote)

            // Verify that the node was inserted as expected
            let matches = appState.rootNode.findChildren(predicate: name)
            if matches.count != 1 {
                Issue.record("New node not found in tree")
                return
            }

            try appState.unlockIdentity(passphrase: PASSPHRASE)
            let plaintext = try Age.decrypt(newPwNode.path)
            #expect(plaintext == password)
        }
        catch {
            Issue.record("\(error.localizedDescription)")
        }
    }

    /// Change the plaintext value of a password
    @Test func modifyPassword() throws {
        let name = getTestcaseNodeName()
        let password = getTestcasePassword()
        do {
            let currentPwNode = try PwManager.submit(
                selectedName: name,
                selectedRelativePath: "/",
                selectedDirectory: false,
                currentPwNode: nil,
                password: password)

            // Reload git tree with new entry
            try appState.reloadGitTree()

            try appState.unlockIdentity(passphrase: PASSPHRASE)
            var plaintext = try Age.decrypt(currentPwNode.path)
            #expect(plaintext == password)

            // Submit anew for the same node with a new password
            let newPwNode = try PwManager.submit(
                selectedName: name, selectedRelativePath: "/",
                selectedDirectory: false, currentPwNode: currentPwNode,
                password: "NewPassword")

            try appState.reloadGitTree()

            plaintext = try Age.decrypt(newPwNode.path)
            #expect(plaintext == "NewPassword")

        }
        catch {
            Issue.record("\(error.localizedDescription)")
        }
    }

    /// Move a node while keeping the same password
    @Test func movePassword() throws {
        let name = getTestcaseNodeName()
        let password = getTestcasePassword()
        do {
            let currentPwNode = try addPasswordHelper(
                name: name,
                relativePath: "blue/a", password: password)

            let newPwNode = try PwManager.submit(
                selectedName: "\(name)-new",
                selectedRelativePath: "/",
                selectedDirectory: false,
                currentPwNode: currentPwNode,
                password: "")  // Keep password

            // Reload git tree with new entry
            try appState.reloadGitTree()

            #expect(FileManager.default.exists(newPwNode.path))
            #expect(!FileManager.default.exists(currentPwNode.path))

            try appState.unlockIdentity(passphrase: PASSPHRASE)
            let plaintext = try Age.decrypt(newPwNode.path)
            #expect(plaintext == password)
        }
        catch {
            Issue.record("\(error.localizedDescription)")
        }
    }

    /// Change the name and decrypted content for a node
    @Test func moveAndModifyPassword() throws {
        let name = getTestcaseNodeName()
        let password = getTestcasePassword()
        do {
            let currentPwNode = try addPasswordHelper(
                name: name,
                relativePath: "blue/a", password: password)

            let newPwNode = try PwManager.submit(
                selectedName: "\(name)-new", selectedRelativePath: "/",
                selectedDirectory: false, currentPwNode: currentPwNode,
                password: password)

            // Reload git tree with new entry
            try appState.reloadGitTree()

            try appState.unlockIdentity(passphrase: PASSPHRASE)
            let plaintext = try Age.decrypt(newPwNode.path)
            #expect(plaintext == password)
        }
        catch {
            Issue.record("\(error.localizedDescription)")
        }
    }

    @Test func deletePassword() throws {
        let name = getTestcaseNodeName()
        let password = getTestcasePassword()
        do {
            let node = try addPasswordHelper(
                name: name,
                relativePath: "blue/a",
                password: password)

            try PwManager.remove(node: node)

            // Reload git tree with new entry
            try appState.reloadGitTree()

            // Verify that the node was removed
            let matches = appState.rootNode.findChildren(predicate: "blue")
                .first!
                .findChildren(predicate: "a").first!
                .findChildren(predicate: node.name)

            #expect(matches.count == 0)
            #expect(!FileManager.default.exists(node.path))
        }
        catch {
            Issue.record("\(error.localizedDescription)")
        }
    }

    @Test func addFolder() throws {
        let name = getTestcaseNodeName()
        do {
            _ = try addFolderHelper(name: name)
        }
        catch {
            Issue.record("\(error.localizedDescription)")
        }
    }

    /// Move 'green/<folder>' -> 'green/<folder>-new'
    @Test func moveFolder() throws {
        let name = getTestcaseNodeName()
        let password = getTestcasePassword()
        do {
            // Create the folder to move and a password beneath it
            let _ = try addPasswordHelper(
                name: "pass",
                relativePath: "green/\(name)",
                password: password)

            let currentPwNode = try PwNode.loadValidatedFrom(
                name: name, relativePath: "green", expectPassword: false,
                checkParents: true, allowNameTaken: true)

            let newPwNode = try PwManager.submit(
                selectedName: "\(name)-new", selectedRelativePath: "green",
                selectedDirectory: true, currentPwNode: currentPwNode,
                password: "")

            // Make sure the folders were moved
            #expect(!FileManager.default.isDir(currentPwNode.path))
            #expect(FileManager.default.isDir(newPwNode.path))

            // Make sure a commit was created
            try appState.reloadGitTree()
            #expect(!appState.localHeadMatchesRemote)
        }
        catch {
            Issue.record("\(error.localizedDescription)")
        }
    }

    @Test func moveEmptyFolders() throws {
        let name = getTestcaseNodeName()
        do {
            let currentPwNode = try PwNode.loadValidatedFrom(
                name: name, relativePath: "/", expectPassword: false,
                checkParents: true, allowNameTaken: true)

            // Create new folders
            try FileManager.default.mkdirp(currentPwNode.path)
            try FileManager.default.mkdirp(
                currentPwNode.path.appending("child"))

            let newPwNode = try PwManager.submit(
                selectedName: "\(name)-new", selectedRelativePath: "/",
                selectedDirectory: true, currentPwNode: currentPwNode,
                password: "")

            #expect(!FileManager.default.isDir(currentPwNode.path))
            #expect(FileManager.default.isDir(newPwNode.path))
        }
        catch {
            Issue.record("\(error.localizedDescription)")
        }
    }

    @Test func deleteEmptyFolders() throws {
        let name = getTestcaseNodeName()
        do {
            let currentPwNode = try PwNode.loadValidatedFrom(
                name: name, relativePath: "/", expectPassword: false,
                checkParents: true, allowNameTaken: true)

            // Create new folders
            try FileManager.default.mkdirp(currentPwNode.path)
            try FileManager.default.mkdirp(
                currentPwNode.path.appending("child"))

            try PwManager.remove(node: currentPwNode)

            #expect(!FileManager.default.isDir(currentPwNode.path))
        }
        catch {
            Issue.record("\(error.localizedDescription)")
        }
    }

    @Test func moveWithSpecialCharactersInPath() throws {
        let folderName = "\(getTestcaseNodeName())-ÅÄÖ-åäö"
        let name = "\(getTestcaseNodeName())-åäö-ÅÖÖ"
        let password = getTestcasePassword()
        do {
            // Add a folder with special characters
            let currentFolderNode = try addFolderHelper(name: folderName)

            // Add a password beneath it with special characters
            _ = try addPasswordHelper(
                name: name,
                relativePath: "/\(folderName)",
                password: password)

            // Move the folder
            let newPwNode = try PwManager.submit(
                selectedName: "\(folderName)-new",
                selectedRelativePath: "/",
                selectedDirectory: true,
                currentPwNode: currentFolderNode,
                password: "")

            // Reload git tree with new entry
            try appState.reloadGitTree()

            #expect(FileManager.default.exists(newPwNode.path))
            #expect(!FileManager.default.exists(currentFolderNode.path))

            // Decrypt the password beneath the new folder path
            try appState.unlockIdentity(passphrase: PASSPHRASE)
            let plaintext = try Age.decrypt(newPwNode.path.appending("\(name).age"))
            #expect(plaintext == password)
        }
        catch {
            Issue.record("\(error.localizedDescription)")
        }
    }

    @Test func badPasswords() throws {
        let name = getTestcaseNodeName()
        let invalidPasswords = [
            String(repeating: "a", count: MAX_PASSWORD_LENGTH + 1),
            "",
        ]

        for invalidPassword in invalidPasswords {
            #expect(throws: AppError.invalidPasswordFormat, performing: {
                try PwManager.submit(
                    selectedName: name,
                    selectedRelativePath: "/",
                    selectedDirectory: false,
                    currentPwNode: nil,
                    password: invalidPassword)
            })
        }
    }

    @Test func badNodeNames() throws {
        let invalidNames = [
            "",
            ROOT_NODE_NAME,
            "name.age",
            "/",
            "/abc/",  // no slashes allowed in node names
            ".",
            ".hidden",
            "not-hidden.",
            "..",
            String(repeating: "a", count: 64 + 1),
            "§",
            "%CC",
            "😵",
        ]

        for invalidName in invalidNames {
            print("Checking: '\(invalidName)'")

            #expect("Invalid folder name", performing: {
                try PwNode.loadValidatedFrom(
                    name: invalidName, relativePath: "/", expectPassword: false,
                    checkParents: false, allowNameTaken: true)
            }, throws: { error in
                // Do not check the exact error message, just that it
                // has the expected type
                let appError = (error as! AppError).localizedDescription
                return appError.starts(with: INVALID_NODE_PATH_ERROR)
            })

            #expect("Invalid password name", performing: {
                try PwNode.loadValidatedFrom(
                    name: invalidName, relativePath: "/", expectPassword: true,
                    checkParents: false, allowNameTaken: true)
            }, throws: { error in
                let appError = (error as! AppError).localizedDescription
                return appError.starts(with: INVALID_NODE_PATH_ERROR)
            })
        }
    }

    @Test func okNodeNames() throws {
        let validNames = [
            "person123@gmail.com",
            "name_with-special.chars",
            "åäöÅÄÖ",
        ]

        for validName in validNames {
            print("Checking: '\(validName)'")
            let _ = try PwNode.loadValidatedFrom(
                name: validName, relativePath: "/", expectPassword: true,
                checkParents: false, allowNameTaken: true)
            let _ = try PwNode.loadValidatedFrom(
                name: validName, relativePath: "/", expectPassword: false,
                checkParents: false, allowNameTaken: true)
        }
    }

    @Test func badNodePaths() throws {
        let password = getTestcasePassword()
        let name = getTestcaseNodeName()

        let node = try addPasswordHelper(
            name: "pass1",
            relativePath: name,
            password: password)

        try FileManager.default.mkdirp(GIT_DIR.appending("\(name)/a"))

        let invalidPairs = [
            // Already taken
            [node.relativePath, "pass1"],
            [node.relativePath, "a"],
            // Invalid names in path
            ["..", "new"],
            [".hidden", "new"],
            ["name.age", "new"],
            ["§", "new"],
            // Already taken name in path
            ["\(node.relativePath)/pass1", "child"],
        ]

        for invalidPair in invalidPairs {
            print("Checking: ('\(invalidPair[0])', '\(invalidPair[1])')")
            #expect("Invalid node path", performing: {
                try PwManager.submit(
                    selectedName: invalidPair[1],
                    selectedRelativePath: invalidPair[0],
                    selectedDirectory: false,
                    currentPwNode: nil,
                    password: password)

            }, throws: { error in
                let appError = (error as! AppError).localizedDescription
                return appError.starts(with: INVALID_NODE_PATH_ERROR)
            })
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    /// Helper to create a passwrod that can be moved etc.
    private func addPasswordHelper(
        name: String,
        relativePath: String,
        password: String
    ) throws -> PwNode {
        try FileManager.default.mkdirp(
            GIT_DIR.appending(relativePath))

        let newPwNode = try PwManager.submit(
            selectedName: name,
            selectedRelativePath: relativePath,
            selectedDirectory: false,
            currentPwNode: nil,
            password: password)

        try Git.push()
        try appState.reloadGitTree()

        return newPwNode
    }

    private func addFolderHelper(name: String) throws -> PwNode {
        let newPwNode = try PwManager.submit(
            selectedName: name,
            selectedRelativePath: "/",
            selectedDirectory: true,
            currentPwNode: nil,
            password: "")

        try appState.reloadGitTree()

        // Verify that the node was inserted as expected
        let matches = appState.rootNode.findChildren(predicate: name)
        if matches.count != 1 {
            Issue.record("New node not found in tree")
        }

        #expect(FileManager.default.isDir(newPwNode.path))
        return newPwNode
    }

    private func getTestcaseNodeName(function: String = #function) -> String {
        let name = function.deletingSuffix("()")
        return "\(name)-\(Int(Date.now.timeIntervalSince1970))"
    }

    private func getTestcasePassword(function: String = #function) -> String {
        return "password-\(getTestcaseNodeName())"
    }
}
