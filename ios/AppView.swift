import SwiftUI
import OSLog


// The remote IP and path should be configurable.
// The remote will control access to each repository based on the source IP
// (assigned from Wireguard config).

// Git repo for each user is initialized remote side with
// .age-recipients and .age-identities already present
// In iOS, we need to:
//  * Clone it
//  * Pull / Push
//  * No conflict resolution, option to start over OR force push


// Views:
// Main view:
//  password list, folders, drop down or new page...
//  Search
//  add button, push button, settings wheel
//
// Create view: (pop over)
// Push button: loading screen --> error or sucess
// Settings view: (pop over)
//  - remote address
//  - tint color
//  - fetch remote updates (automatically on startup instead?)
//  - reset all data
//  - version info


struct AppView: View {
    @AppStorage("remote") private var remote: String = ""
    let repo = FileManager.default.appDataDirectory.appending(path: "git")

    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 20) {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)

                Text("Clone").onTapGesture {
                    // TODO progress view
                    if remote.isEmpty {
#if targetEnvironment(simulator)
                        remote = "git://127.0.0.1/james"
#else
                        remote = "git://10.0.1.8/james"
#endif
                    }

                    Git.clone(remote: remote, into: repo);
                }

                Text("Encrypt").onTapGesture {
                    let recipient = repo.appending(path: ".age-recipients")
                    let outpath = repo.appending(path: "iOS.age")
                    let _ = Age.encrypt(recipient: recipient,
                                        outpath: outpath,
                                        plaintext: "wow")
                }

                Text("Unlock").onTapGesture {
                    let encryptedIdentity = repo.appending(path: ".age-identities")
                    let _ = Age.unlockIdentity(encryptedIdentity, passphrase: "x")
                }

                Text("Lock").onTapGesture {
                    let _ = Age.lockIdentity()
                }

                Text("Decrypt").onTapGesture {
                    let path = repo.appending(path: "iOS.age")

                    let clock = ContinuousClock()
                    let elapsed = clock.measure {
                        logger.info("Decryption: BEGIN")
                        let plaintext = Age.decrypt(path)
                        logger.info("Decrypted: '\(plaintext)'")
                    }
                    logger.info("Decryption: END [\(elapsed)]")
                }

                NavigationLink("Settings") {
                    SettingsView()
                }
            }
            .font(.system(size: 24))
            .padding()
        }
    }
}
