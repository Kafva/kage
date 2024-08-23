import XCTest

final class kageTests: XCTestCase {

    let remote = "git://127.0.0.1/james.git"
    let username = "james"
    var appState: AppState!

    override func setUpWithError() throws {
        self.appState = AppState()
        try? FileManager.default.removeItem(at: G.gitDir)
        do {
            try Git.clone(remote: remote)
            try Git.configSetUser(username: username)
            try appState.reloadGitTree()
        }
        catch {
            try? FileManager.default.removeItem(at: G.gitDir)
            print("\(error.localizedDescription)")
            XCTFail()
        }
    }

    override func tearDownWithError() throws {
    }

    func testAdd() throws {
        XCTAssert(true)
    }
}
