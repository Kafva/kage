import XCTest

final class kageTests: XCTestCase {

    var rootNode: PwNode!

    override func setUpWithError() throws {
        // Initialize AppState with a fake tree of nodes
        self.rootNode = PwNode(url: G.gitDir, children: [])
    }

    override func tearDownWithError() throws {
    }

    func testBasic() throws {
        XCTAssert(self.rootNode.name == "/")
    }
}
