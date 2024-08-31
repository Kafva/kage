import SwiftUI
import XCTest

@testable import kage

final class kageTests: XCTestCase {
    var appState: AppState!

    /// Expected passphrase for the test data
    static let passphrase = "x"
    static let remote = "git://127.0.0.1/ios.git"
    static let username = "ios"

    /// Setup to run ONCE before any tests start
    override class func setUp() {
        print("Running setup...")
        try? FileManager.default.removeItem(at: G.gitDir)
        do {
            try Git.clone(remote: Self.remote)
        }
        catch {
            XCTFail("\(error.localizedDescription)")
        }
    }

    /// Setup to run before each test method
    override func setUpWithError() throws {
        print("Running test case setup...")
        // Stop when a XCTAssert() fails (why is this not the default...?)
        self.continueAfterFailure = false

        // (Re-)initialise app state and reset
        self.appState = AppState()
        try Git.configSetUser(username: Self.username)
        try Git.reset()
        try appState.reloadGitTree()
    }

    /// Teardown to run ONCE after all tests
    override class func tearDown() {
        print("Running teardown...")
        // Each test case expects that it starts out being up-to-date
        do {
            try Git.push()
        }
        catch {
            print("Failed to push on exit: \(error.localizedDescription)")
        }
    }

    /// Teardown to run after each test method
    override func tearDownWithError() throws {
        print("Running test case teardown...")
    }

    /// Add a new password and push it to the remote
    func testAddPassword() throws {
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
            XCTAssert(!appState.localHeadMatchesRemote)

            // Verify that the node was inserted as expected
            let matches = appState.rootNode.findChildren(predicate: name)
            if matches.count != 1 {
                XCTFail("New node not found in tree")
                return
            }

            try appState.unlockIdentity(passphrase: Self.passphrase)
            let plaintext = try Age.decrypt(newPwNode.url)
            XCTAssert(plaintext == password)
        }
        catch {
            XCTFail("\(error.localizedDescription)")
        }
    }

    /// Change the plaintext value of a password
    func testModifyPassword() throws {
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

            try appState.unlockIdentity(passphrase: Self.passphrase)
            var plaintext = try Age.decrypt(currentPwNode.url)
            XCTAssert(plaintext == password)

            // Submit anew for the same node with a new password
            let newPwNode = try PwManager.submit(
                selectedName: name, selectedRelativePath: "/",
                selectedDirectory: false, currentPwNode: currentPwNode,
                password: "NewPassword")

            try appState.reloadGitTree()

            plaintext = try Age.decrypt(newPwNode.url)
            XCTAssert(plaintext == "NewPassword")

        }
        catch {
            XCTFail("\(error.localizedDescription)")
        }
    }

    /// Move a node while keeping the same password
    func testMovePassword() throws {
        let name = getTestcaseNodeName()
        let password = getTestcasePassword()
        do {
            let currentPwNode = try addPassword(
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

            XCTAssert(FileManager.default.exists(newPwNode.url))
            XCTAssertFalse(FileManager.default.exists(currentPwNode.url))

            try appState.unlockIdentity(passphrase: Self.passphrase)
            let plaintext = try Age.decrypt(newPwNode.url)
            XCTAssert(plaintext == password)
        }
        catch {
            XCTFail("\(error.localizedDescription)")
        }
    }

    /// Change the name and decrypted content for a node
    func testMoveAndModifyPassword() throws {
        let name = getTestcaseNodeName()
        let password = getTestcasePassword()
        do {
            let currentPwNode = try addPassword(
                name: name,
                relativePath: "blue/a", password: password)

            let newPwNode = try PwManager.submit(
                selectedName: "\(name)-new", selectedRelativePath: "/",
                selectedDirectory: false, currentPwNode: currentPwNode,
                password: password)

            // Reload git tree with new entry
            try appState.reloadGitTree()

            try appState.unlockIdentity(passphrase: Self.passphrase)
            let plaintext = try Age.decrypt(newPwNode.url)
            XCTAssert(plaintext == password)
        }
        catch {
            XCTFail("\(error.localizedDescription)")
        }
    }

    func testDeletePassword() throws {
        let name = getTestcaseNodeName()
        let password = getTestcasePassword()
        do {
            let node = try addPassword(
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

            XCTAssert(matches.count == 0)
            XCTAssertFalse(FileManager.default.exists(node.url))
        }
        catch {
            XCTFail("\(error.localizedDescription)")
        }
    }

    /// Move 'green/<folder>' -> 'green/<folder>-new'
    func testMoveFolder() throws {
        let name = getTestcaseNodeName()
        let password = getTestcasePassword()
        do {
            // Create the folder to move and a password beneath it
            let _ = try addPassword(
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
            XCTAssertFalse(FileManager.default.isDir(currentPwNode.url))
            XCTAssert(FileManager.default.isDir(newPwNode.url))

            // Make sure a commit was created
            try appState.reloadGitTree()
            XCTAssertFalse(appState.localHeadMatchesRemote)
        }
        catch {
            XCTFail("\(error.localizedDescription)")
        }
    }

    func testMoveEmptyFolders() throws {
        let name = getTestcaseNodeName()
        do {
            let currentPwNode = try PwNode.loadValidatedFrom(
                name: name, relativePath: "/", expectPassword: false,
                checkParents: true, allowNameTaken: true)

            // Create new folders
            try FileManager.default.mkdirp(currentPwNode.url)
            try FileManager.default.mkdirp(
                currentPwNode.url.appending(path: "child"))

            let newPwNode = try PwManager.submit(
                selectedName: "\(name)-new", selectedRelativePath: "/",
                selectedDirectory: true, currentPwNode: currentPwNode,
                password: "")

            XCTAssertFalse(FileManager.default.isDir(currentPwNode.url))
            XCTAssert(FileManager.default.isDir(newPwNode.url))
        }
        catch {
            XCTFail("\(error.localizedDescription)")
        }
    }

    func testDeleteEmptyFolders() throws {
        let name = getTestcaseNodeName()
        do {
            let currentPwNode = try PwNode.loadValidatedFrom(
                name: name, relativePath: "/", expectPassword: false,
                checkParents: true, allowNameTaken: true)

            // Create new folders
            try FileManager.default.mkdirp(currentPwNode.url)
            try FileManager.default.mkdirp(
                currentPwNode.url.appending(path: "child"))

            try PwManager.remove(node: currentPwNode)

            XCTAssertFalse(FileManager.default.isDir(currentPwNode.url))
        }
        catch {
            XCTFail("\(error.localizedDescription)")
        }
    }

    func testBadPasswords() throws {
        let name = getTestcaseNodeName()
        let invalidPasswords = [
            String(repeating: "a", count: G.maxPasswordLength + 1),
            "",
        ]

        for invalidPassword in invalidPasswords {
            XCTAssertThrowsError(
                try PwManager.submit(
                    selectedName: name,
                    selectedRelativePath: "/",
                    selectedDirectory: false,
                    currentPwNode: nil,
                    password: invalidPassword)
            ) { error in
                XCTAssertEqual(
                    error as! AppError, AppError.invalidPasswordFormat)
            }
        }
    }

    func testBadNodeNames() throws {
        let invalidNames = [
            "",
            G.rootNodeName,
            "name.age",
            "/",
            "/abc/",  // no slashes allowed in node names
            ".",
            ".hidden",
            "not-hidden.",
            "..",
            String(repeating: "a", count: 64 + 1),
            "§",
            "😵",
        ]

        for invalidName in invalidNames {
            print("Checking: '\(invalidName)'")
            XCTAssertThrowsError(
                try PwNode.loadValidatedFrom(
                    name: invalidName, relativePath: "/", expectPassword: false,
                    checkParents: false, allowNameTaken: true)
            ) { error in
                // Do not check the exact error message, just that it
                // has the expected type
                let appError = (error as! AppError).localizedDescription
                let invalidNodePathError = AppError.invalidNodePath("")
                    .localizedDescription
                XCTAssert(appError.starts(with: invalidNodePathError))
            }

            XCTAssertThrowsError(
                try PwNode.loadValidatedFrom(
                    name: invalidName, relativePath: "/", expectPassword: true,
                    checkParents: false, allowNameTaken: true)
            ) { error in
                // Do not check the exact error message, just that it
                // has the expected type
                let appError = (error as! AppError).localizedDescription
                let invalidNodePathError = AppError.invalidNodePath("")
                    .localizedDescription
                XCTAssert(appError.starts(with: invalidNodePathError))
            }
        }
    }

    func testOkNodeNames() throws {
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

    func testBadNodePaths() throws {
        let password = getTestcasePassword()
        let name = getTestcaseNodeName()

        let node = try addPassword(
            name: "pass1",
            relativePath: name,
            password: password)

        try FileManager.default.mkdirp(G.gitDir.appending(path: "\(name)/a"))

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
            XCTAssertThrowsError(
                try PwManager.submit(
                    selectedName: invalidPair[1],
                    selectedRelativePath: invalidPair[0],
                    selectedDirectory: false,
                    currentPwNode: nil,
                    password: password)

            ) { error in
                let appError = (error as! AppError).localizedDescription
                let invalidNodePathError = AppError.invalidNodePath("")
                    .localizedDescription
                XCTAssert(appError.starts(with: invalidNodePathError))
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    /// Helper to create a passwrod that can be moved etc.
    private func addPassword(
        name: String,
        relativePath: String,
        password: String
    ) throws -> PwNode {
        try FileManager.default.mkdirp(
            G.gitDir.appending(path: relativePath))

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

    private func getTestcaseNodeName(function: String = #function) -> String {
        let name = function.deletingSuffix("()")
        return "\(name)-\(Int(Date.now.timeIntervalSince1970))"
    }

    private func getTestcasePassword(function: String = #function) -> String {
        return "password-\(getTestcaseNodeName())"
    }
}
