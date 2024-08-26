import SwiftUI
import XCTest

@testable import kage

/// Test data:
/// .
/// ├── blue
/// │   └── a
/// │       ├── pass1.age
/// │       ├── pass2.age
/// │       ├── pass3.age
/// │       ├── pass4.age
/// │       └── pass5.age
/// ├── green
/// │   ├── a
/// │   │   ├── pass1.age
/// │   │   ├── pass2.age
/// │   │   ├── pass3.age
/// │   │   ├── pass4.age
/// │   │   └── pass5.age
/// │   └── b
/// │       ├── pass1.age
/// │       ├── pass2.age
/// │       ├── pass3.age
/// │       ├── pass4.age
/// │       └── pass5.age
/// ├── invalid_content
/// └── red
///     ├── a
///     │   ├── pass1.age
///     │   ├── pass2.age
///     │   ├── pass3.age
///     │   ├── pass4.age
///     │   └── pass5.age
///     ├── pass1.age
///     ├── pass2.age
///     ├── pass3.age
///     ├── pass4.age
///     └── pass5.age
final class kageTests: XCTestCase {
    var appState: AppState!

    /// Expected passphrase for the test data
    static let passphrase = "x"
    static let remote = "git://127.0.0.1/james.git"
    static let username = "james"

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
            _ = try doSubmit(
                name: name, relativeFolderPath: "/", password: password)

            // Reload git tree with new entry
            try appState.reloadGitTree()

            // Verify that the node was inserted as expected
            let matches = appState.rootNode.findChildren(predicate: name)
            guard let node = matches.first else {
                XCTFail("New node not found in tree")
                return
            }
            XCTAssert(node.name == name)

            try appState.unlockIdentity(passphrase: Self.passphrase)
            let plaintext = try Age.decrypt(node.url)
            XCTAssert(plaintext == password)

            // Verify that we can push the changes
            XCTAssert(!appState.localHeadMatchesRemote)
            try Git.push()
            try appState.reloadGitTree()
            XCTAssert(appState.localHeadMatchesRemote)
        }
        catch {
            XCTFail("\(error.localizedDescription)")
        }
    }

    func testMovePassword() throws {
        let name = getTestcaseNodeName()
        let password = ""  // Keep original password
        do {
            let currentPwNode = try PwNode.loadValidatedFrom(
                name: "pass2",
                relativeFolderPath: "blue/a",
                isDir: false)

            let newPwNode = try doSubmit(
                name: name, relativeFolderPath: "/", password: password,
                currentPwNode: currentPwNode)

            // Reload git tree with new entry
            try appState.reloadGitTree()

            // Verify that the node was inserted as expected
            let matches = appState.rootNode.findChildren(predicate: name)
            guard let node = matches.first else {
                XCTFail("New node not found in tree")
                return
            }

            XCTAssert(node.name == name)
            XCTAssert(FileManager.default.exists(newPwNode.url))
            XCTAssertFalse(FileManager.default.exists(currentPwNode.url))
        }
        catch {
            XCTFail("\(error.localizedDescription)")
        }
    }

    func testDeletePassword() throws {
        do {
            let node = try PwNode.loadValidatedFrom(
                name: "pass5",
                relativeFolderPath: "blue/a",
                isDir: false)
            let predicate = node.relativePath.deletingSuffix(".age")

            var matches = appState.rootNode.findChildren(predicate: predicate)
            XCTAssert(matches.count > 0)
            XCTAssert(FileManager.default.exists(node.url))

            try PwManager.remove(node: node)

            // Reload git tree with new entry
            try appState.reloadGitTree()

            // Verify that the node was removed
            matches = appState.rootNode.findChildren(predicate: predicate)

            XCTAssert(matches.count == 0)
            XCTAssertFalse(FileManager.default.exists(node.url))
        }
        catch {
            XCTFail("\(error.localizedDescription)")
        }

    }

    func testMoveFolder() throws {
        let name = getTestcaseNodeName()
        do {
            let currentPwNode = try PwNode.loadValidatedFrom(
                name: "a",
                relativeFolderPath: "green",
                isDir: true)

            let newPwNode = try doSubmit(
                name: name, relativeFolderPath: "/green", password: "",
                currentPwNode: currentPwNode)

            // Reload git tree with new entry
            try appState.reloadGitTree()

            // Verify that the node was inserted as expected
            let matches = appState.rootNode.findChildren(predicate: name)
            guard let node = matches.first else {
                XCTFail("New node not found in tree")
                return
            }

            XCTAssert(node.name == name)
            XCTAssert(FileManager.default.exists(newPwNode.url))
            XCTAssertFalse(FileManager.default.exists(currentPwNode.url))
        }
        catch {
            XCTFail("\(error.localizedDescription)")
        }

    }

    func testDeleteEmptyFolders() throws {
        let name = getTestcaseNodeName()
        do {
            let node = try doSubmit(
                name: name, relativeFolderPath: "red", password: "",
                directorySelected: true)
            let childNode = try doSubmit(
                name: "a", relativeFolderPath: "red/\(name)", password: "",
                directorySelected: true)

            XCTAssert(FileManager.default.isDir(node.url))
            XCTAssert(FileManager.default.isDir(childNode.url))

            try PwManager.remove(node: node)

            XCTAssertFalse(FileManager.default.isDir(node.url))
            XCTAssertFalse(FileManager.default.isDir(childNode.url))
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

        do {
            let newPwNode = try PwNode.loadValidatedFrom(
                name: name,
                relativeFolderPath: "/",
                isDir: false)

            for invalidPassword in invalidPasswords {
                XCTAssertThrowsError(
                    try PwManager.submit(
                        currentPwNode: nil,
                        newPwNode: newPwNode,
                        directorySelected: false,
                        password: invalidPassword,
                        confirmPassword: invalidPassword,
                        generate: false)
                ) { error in
                    XCTAssertEqual(
                        error as! AppError, AppError.invalidPasswordFormat)
                }
            }
        }
        catch {
            XCTFail("\(error.localizedDescription)")
        }
    }

    func testBadNodeNames() throws {
        let invalidNames = [
            "",
            G.rootNodeName,
            "/",
            "/abc/",  // no slashes allowed in node names
            ".",
            "..",
            "name.age",
            String(repeating: "a", count: 64 + 1),
            "§",
            "😵",
        ]

        for invalidName in invalidNames {
            XCTAssertThrowsError(
                try PwNode.loadValidatedFrom(
                    name: invalidName,
                    relativeFolderPath: "/",
                    isDir: false)
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

    func testBadNodePaths() throws {
        let invalidPairs = [
            // Already taken
            ["red/a", "pass1"],
            ["red", "a"],
            // Invalid names in path
            ["..", "new"],
            [".hidden", "new"],
            ["name.age", "new"],
            ["§", "new"],
            // Already taken name in path
            ["red/a/pass1", "child"],
            ["red/invalid_content", "child"],
            ["red/invalid_content/non_existant", "child"],
        ]
        let password = getTestcasePassword()

        for invalidPair in invalidPairs {
            XCTAssertThrowsError(
                try doSubmit(
                    name: invalidPair[1],
                    relativeFolderPath: invalidPair[0],
                    password: password
                )
            ) { error in
                let appError = (error as! AppError).localizedDescription
                let invalidNodePathError = AppError.invalidNodePath("")
                    .localizedDescription
                XCTAssert(appError.starts(with: invalidNodePathError))
            }
        }
    }

    private func doSubmit(
        name: String, relativeFolderPath: String, password: String,
        currentPwNode: PwNode? = nil,
        confirmPassword: String? = nil,
        directorySelected: Bool = false
    ) throws -> PwNode {
        let newPwNode = try PwNode.loadValidatedFrom(
            name: name,
            relativeFolderPath: relativeFolderPath,
            isDir: directorySelected)

        try PwManager.submit(
            currentPwNode: currentPwNode,
            newPwNode: newPwNode,
            directorySelected: directorySelected,
            password: password,
            confirmPassword: confirmPassword ?? password,
            generate: false)
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
