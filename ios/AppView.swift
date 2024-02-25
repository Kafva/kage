import SwiftUI
import OSLog

let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                    category: "generic")

// The remote IP and path should be configurable.
// The server will control access to each repository based on the source IP
// (assigned from Wireguard config).

// Git repo for each user is initialized server side with
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
//  - server address
//  - tint color
//  - fetch remote updates (automatically on startup instead?)
//  - reset all data
//  - version info


struct AppView: View {
    @AppStorage("server") private var server: String = ""
    let repo = FileManager.default.appDataDirectory.appending(path: "store")

    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)

                Text("Clone!")
                .onTapGesture {
                    // TODO progress view
                    clone()
                }
                Text("Encrypt").onTapGesture {
                    age_test()

                }
                NavigationLink("Settings") {
                    SettingsView()
                }
            }
            .padding()

        }
    }

    func age_test() {
        let identityUrl = URL(string: "\(repo)/.age-identities")!
        let recipientUrl = URL(string: "\(repo)/.age-recipients")!
        do {
            //let encryptedIdentity = try String(contentsOf: identityUrl, encoding: .utf8)
            let recepient = (try String(contentsOf: recipientUrl, encoding: .utf8))
                                .trimmingCharacters(in: .whitespacesAndNewlines)
            let recepientC = recepient.cString(using: .utf8)!

            let plaintextC = "wow".cString(using: .utf8)!

            let outSize: CInt = 1024
            let outC = UnsafeMutableRawPointer.allocate(byteCount: Int(outSize), alignment: 1)

            // TODO: Output argument not needed, provide filepath instead...
            let ciphertextSize = ffi_age_encrypt(plaintext: plaintextC,
                                                 recepient: recepientC,
                                                 out: outC,
                                                 outsize: outSize)
            if ciphertextSize > 0 {
                let ciphertext = Data(bytes: outC, count: Int(ciphertextSize))
                logger.info("Encryption OK: \(ciphertextSize) byte(s)")
                logger.info("Data: \(ciphertext[10])")
            }

            outC.deallocate()

        } catch {
            logger.error("\(error)")
        }
    }

    func clone() {
        try? FileManager.default.removeItem(at: repo)

#if targetEnvironment(simulator)
        if server.isEmpty {
            server = "git://127.0.0.1/james"
        }
#endif

        let intoC = repo.path().cString(using: .utf8)!
        let urlC = server.cString(using: .utf8)!

        logger.debug("Cloning from: \(server)")
        let r = ffi_git_clone(url: urlC, into: intoC);
        if r != 0 {
            logger.error("git clone failed: \(r)")
            return
        }
        logger.debug("git clone OK")
    }
}

extension FileManager {
    var appDataDirectory: URL {
        let urls = self.urls(
            for: .documentDirectory,
            in: .userDomainMask)
        return urls[0]
    }
}
