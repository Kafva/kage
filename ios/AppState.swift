import SwiftUI

class AppState: ObservableObject {
    @Published var identityIsUnlocked: Bool = false

    func unlockIdentity(passphrase: String) -> Bool {
        let encryptedIdentity = GIT_DIR.appending(path: ".age-identities")
        identityIsUnlocked = Age.unlockIdentity(encryptedIdentity, 
                                                passphrase: passphrase)
        return identityIsUnlocked
    }

    func lockIdentity() -> Bool {
        if Age.lockIdentity() {
            identityIsUnlocked = false
        } else {
            LOGGER.warning("Failed to lock identity")
        }
        return identityIsUnlocked
    }
}

