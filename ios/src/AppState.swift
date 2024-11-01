import Network
import SwiftUI

@_silgen_name("ffi_free_cstring")
func ffi_free_cstring(_ ptr: UnsafeMutablePointer<CChar>?)

class AppState: ObservableObject {
    @Published var identityUnlockedAt: Date? = nil
    @Published var rootNode: PwNode = PwNode(url: G.gitDir, children: [])
    @Published var localHeadMatchesRemote: Bool = true

    var identityIsUnlocked: Bool {
        return identityUnlockedAt != nil
    }

    func reloadGitTree() throws {
        rootNode = try PwNode.loadRecursivelyFrom(G.gitDir)
        localHeadMatchesRemote = try Git.localHeadMatchesRemote()
    }

    func unlockIdentity(passphrase: String) throws {
        let encryptedIdentity = G.gitDir.appending(path: ".age-identities")
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
