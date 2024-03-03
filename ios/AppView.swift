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


struct PwNode: Identifiable {
    let id = UUID()
    let url: URL
    let children: [PwNode]?

    var name: String {
         return url.deletingPathExtension().lastPathComponent
    }

    var isFile: Bool {
        return (children ?? []).isEmpty
    }

    static func loadChildren(_ fromDir: URL) throws -> Self {
        var children: [Self] = []

        for url in try FileManager.default.ls(fromDir) {
            let node = FileManager.default.isDir(url) ?
                                try loadChildren(url) :
                                PwNode(url: url, children: nil)

            children.append(node)
        }

        return PwNode(url: fromDir, children: children)
    }

    func show() {
        if !self.isFile {
            return
        }

        let clock = ContinuousClock()
        let elapsed = clock.measure {
            logger.info("Decryption: BEGIN")
            let plaintext = Age.decrypt(self.url)
            logger.info("Decrypted: '\(plaintext)'")
        }
        logger.info("Decryption: END [\(elapsed)]")
    }
}

struct AppView: View {
    @AppStorage("remote") private var remote: String = ""
    @State private var searchText = ""
    @State private var gitTree: [PwNode] = []
    let gitDir = FileManager.default.gitDirectory

    var searchResults: [PwNode] {
        if searchText.isEmpty {
            return gitTree
        } else {
            return gitTree // TODO
            //return gitTree.filter { $0.contains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 20) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gear")
                }

                Text("Unlock").onTapGesture {
                    let encryptedIdentity = gitDir.appending(path: ".age-identities")
                    let _ = Age.unlockIdentity(encryptedIdentity, passphrase: "x")
                }

                Text("Lock").onTapGesture {
                    let _ = Age.lockIdentity()
                }

                List(searchResults, children: \.children) { node in
                    Text("\(node.name)")
                        .font(.system(size: 24))
                        .onTapGesture {
                            node.show()
                        }
                }
                .searchable(text: $searchText)
            }
        }
        .padding()
        .onAppear {
            do {
                try? FileManager.default.removeItem(at: gitDir)
                Git.clone(remote: remote,  into: gitDir)
                gitTree = (try PwNode.loadChildren(gitDir)).children ?? []

            } catch {
                logger.error("\(error)")
            }
        }
    }
}
