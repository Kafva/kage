import Network
import SwiftUI

class AppState: ObservableObject {
    @Published var identityIsUnlocked: Bool = false
    @Published var rootNode: PwNode = PwNode(url: G.gitDir, children: [])
    @Published var hasLocalChanges: Bool = false

    /// Description of last high-level error that occured
    @Published var currentError: String?

    func reloadGitTree() throws {
        rootNode = try PwNode.loadFrom(G.gitDir)
        hasLocalChanges = try Git.indexHasLocalChanges()
    }

    func uiError(_ message: String, line: Int = #line, fileID: String = #fileID)
    {
        G.logger.error(message, line: line, fileID: fileID)
        currentError = message
    }

    func unlockIdentity(passphrase: String) throws {
        let encryptedIdentity = G.gitDir.appending(path: ".age-identities")
        try Age.unlockIdentity(
            encryptedIdentity,
            passphrase: passphrase)
        identityIsUnlocked = true
    }

    func lockIdentity() throws {
        try Age.lockIdentity()
        identityIsUnlocked = false
    }
}
