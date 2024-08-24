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

    let remote = "git://127.0.0.1/james.git"
    let username = "james"
    var appState: AppState!

    override func setUpWithError() throws {
        self.appState = AppState()
        try? FileManager.default.removeItem(at: G.gitDir)
        try Git.clone(remote: remote)
        try Git.configSetUser(username: username)
        try appState.reloadGitTree()
    }

    override func tearDownWithError() throws {
    }

    /// Add a new password and push it to the remote
    func testAdd() throws {
        do {
            let newPwNode = try PwNode.loadFrom(
                name: "NewPassword",
                relativeFolderPath: "red",
                isDir: false)

            try PwManager.submit(
                currentPwNode: nil,
                newPwNode: newPwNode,
                isDir: false,
                password: "password",
                confirmPassword: "password",
                generate: false)

            // Reload git tree with new entry
            try appState.reloadGitTree()
        }
        catch {
            G.logger.error("\(error.localizedDescription)")
        }
    }
}
