import SwiftUI
import Network

class AppState: ObservableObject {
    @Published var identityIsUnlocked: Bool = false
    @Published var rootNode: PwNode = PwNode(url: G.gitDir, children: [])
    @Published var hasLocalChanges: Bool = false

    let monitor = NWPathMonitor()

    /// Is there a VPN interface active?
    @Published var vpnActive: Bool = false

    init() {
        monitor.start(queue: DispatchQueue.global(qos: .background))

        // Triggered whenever the connectivity state changes
        monitor.pathUpdateHandler = { [self] networkPath in
            DispatchQueue.main.async { [self] in
                if networkPath.status == .satisfied {
#if targetEnvironment(simulator)
                    vpnActive = true
#else
                    // We consider ourselves online if there is an 'other' (VPN)
                    // interface available.
                    vpnActive = networkPath.availableInterfaces
                                        .contains(where: { $0.type == .other })
#endif
                }
                G.logger.debug("VPN interface active: \(self.vpnActive ? "yes" : "no")")
            }
        }
    }

    deinit {
        monitor.cancel()
    }

    func reloadGitTree() throws {
        rootNode = try PwNode.loadFrom(G.gitDir)
        hasLocalChanges = try Git.indexHasLocalChanges()
    }

    func unlockIdentity(passphrase: String) throws {
        let encryptedIdentity = G.gitDir.appending(path: ".age-identities")
        try Age.unlockIdentity(encryptedIdentity,
                               passphrase: passphrase)
        identityIsUnlocked = true
    }

    func lockIdentity() throws {
        try Age.lockIdentity()
        identityIsUnlocked = false
    }
}

