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
            VStack(alignment: .center, spacing: 5) {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)

                Text("Clone")
                .onTapGesture {
                    // TODO progress view
                    clone()
                }
                Text("Encrypt").onTapGesture {
                    ageEncrypt(outpath: "\(repo.path())/from_ios.age", plaintext: "wow")
                }
                Text("Decrypt").onTapGesture {
                    let plaintext = ageDecrypt(path: "\(repo.path())/from_ios.age", passphrase: "x")
                    logger.info("Decrypted: \(plaintext)")
                }
                NavigationLink("Settings") {
                    SettingsView()
                }
            }
            .padding()

        }
    }

    func ageDecrypt(path: String, passphrase: String) -> String {
        do {
            let identityUrl = try guardLet(URL(string: "\(repo)/.age-identities"),
                                       AppError.urlError("\(repo)/.age-identities"))

            let encryptedIdentity = try String(contentsOf: identityUrl, encoding: .utf8)

            let encryptedIdentityC = try guardLet(encryptedIdentity.cString(using: .utf8), AppError.cStringError)
            let pathC              = try guardLet(path.cString(using: .utf8), AppError.cStringError)
            let passphraseC        = try guardLet(passphrase.cString(using: .utf8), AppError.cStringError)

            let outsize: CInt = 1024
            let outC = UnsafeMutableRawPointer.allocate(byteCount: Int(outsize), alignment: 1)

            logger.info("encryptedIdentity: \(encryptedIdentity)")
            let written = ffi_age_decrypt_with_identity(path: pathC,
                                                        encryptedIdentity: encryptedIdentityC,
                                                        passphrase: passphraseC,
                                                        out: outC,
                                                        outsize: outsize)

            if written > 0 {
                let data = Data(bytes: outC, count: Int(written))

                let plaintext = String(decoding: data, as: UTF8.self)

                if !plaintext.isEmpty {
                    outC.deallocate()
                    return plaintext
                }
            }

            outC.deallocate()
            logger.error("Decryption failed: \(Int(written))")

        } catch {
            logger.error("\(error)")
        }

        return ""
    }

    func ageEncrypt(outpath: String, plaintext: String) {
        do {
            let recipientUrl = try guardLet(URL(string: "\(repo)/.age-recipients"),
                                            AppError.urlError("\(repo)/.age-recipients"))

            let recepient = (try String(contentsOf: recipientUrl, encoding: .utf8))
                                .trimmingCharacters(in: .whitespacesAndNewlines)

            let recepientC = try guardLet(recepient.cString(using: .utf8), AppError.cStringError)
            let plaintextC = try guardLet(plaintext.cString(using: .utf8), AppError.cStringError)
            let outpathC   = try guardLet(outpath.cString(using: .utf8), AppError.cStringError)

            let r = ffi_age_encrypt(plaintext: plaintextC,
                                    recepient: recepientC,
                                    outpath: outpathC)
            if r == 0 {
                logger.info("Created: \(outpath)")
            }
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

func guardLet<T>(_ value: T?, _ error: Error) throws -> T {
    guard let unwrappedValue = value else {
        throw error
    }
    return unwrappedValue
}

extension FileManager {
    var appDataDirectory: URL {
        let urls = self.urls(
            for: .documentDirectory,
            in: .userDomainMask)
        return urls[0]
    }
}

enum AppError: Error, LocalizedError {
    case urlError(String)
    case cStringError

    var errorDescription: String? {
        switch self {
        case .urlError(let value):
            return "URL parsing failure: \(value)"
        case .cStringError:
            return "Cstring conversion failure"
        }
    }
}

