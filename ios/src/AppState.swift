import Network
import SwiftUI

@_silgen_name("ffi_free_cstring")
func ffi_free_cstring(_ ptr: UnsafeMutablePointer<CChar>?)

class AppState: ObservableObject {
    @Published var identityIsUnlocked: Bool = false
    @Published var rootNode: PwNode = PwNode(url: G.gitDir, children: [])
    @Published var hasLocalChanges: Bool = false
    private var lockTimer: DispatchSourceTimer?

    /// Description of last high-level error that occurred
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

        // Automatically lock the identity after a while
        lockTimer?.cancel()
        lockTimer = DispatchSource.makeTimerSource(queue: .global())
        lockTimer?.schedule(deadline: .now() + 120)
        lockTimer?.setEventHandler {
            DispatchQueue.main.async {
                do {
                    try self.lockIdentity()
                }
                catch {
                    G.logger.error("\(error.localizedDescription)")
                }
            }
        }
        lockTimer?.resume()
    }

    func lockIdentity() throws {
        if !identityIsUnlocked {
            return
        }
        try Age.lockIdentity()
        identityIsUnlocked = false
    }
}
