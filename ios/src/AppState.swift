import Network
import SwiftUI

// periphery: ignore
@_silgen_name("ffi_free_cstring")
func ffi_free_cstring(_ ptr: UnsafeMutablePointer<CChar>?)

class AppState: ObservableObject {
    @Published var backgroundTaskInProgress = false
    @Published var identityUnlockedAt: Date? = nil
    @Published var rootNode: PwNode = PwNode(path: GIT_DIR, children: [])
    @Published var localHeadMatchesRemote: Bool = true

    var identityIsUnlocked: Bool {
        return identityUnlockedAt != nil
    }

    func reloadGitTree() throws {
        rootNode = try PwNode.loadRecursivelyFrom(GIT_DIR)
        localHeadMatchesRemote = try Git.localHeadMatchesRemote()
    }

    func unlockIdentity(passphrase: String) throws {
        let encryptedIdentity = GIT_DIR.appending(".age-identities")
        try Age.unlockIdentity(
            encryptedIdentity,
            passphrase: passphrase)
        identityUnlockedAt = .now
    }

    func lockIdentity() throws {
        try Age.lockIdentity()
        identityUnlockedAt = nil
    }
}
