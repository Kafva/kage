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
    func testAdd() throws {
        let name = getTestcaseNodeName()
        let password = getTestcasePassword()
        do {
            try doSubmit(
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

    func testDeleteEmptyFolder() throws {
        let name = getTestcaseNodeName()
        do {
            let newPwNode = try PwNode.loadValidatedFrom(
                name: name,
                relativeFolderPath: "red",
                isDir: true)

            try PwManager.submit(
                currentPwNode: nil,
                newPwNode: newPwNode,
                directorySelected: true,
                password: "",
                confirmPassword: "",
                generate: false)

            XCTAssert(FileManager.default.isDir(newPwNode.url))

            try PwManager.remove(node: newPwNode)

            XCTAssertFalse(FileManager.default.isDir(newPwNode.url))
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
        confirmPassword: String? = nil
    ) throws {
        let newPwNode = try PwNode.loadValidatedFrom(
            name: name,
            relativeFolderPath: relativeFolderPath,
            isDir: false)

        try PwManager.submit(
            currentPwNode: nil,
            newPwNode: newPwNode,
            directorySelected: false,
            password: password,
            confirmPassword: confirmPassword ?? password,
            generate: false)
    }

    private func getTestcaseNodeName(function: String = #function) -> String {
        let name = function.deletingSuffix("()")
        return "\(name)-\(Int(Date.now.timeIntervalSince1970))"
    }

    private func getTestcasePassword(function: String = #function) -> String {
        return "password-\(getTestcaseNodeName())"
    }
}
