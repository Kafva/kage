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
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var gitTree: [PwNode] = []

    var searchResults: [PwNode] {
        if searchText.isEmpty {
            return gitTree
        } else {
            // TODO do not show sibilings of match
            let rootNode = PwNode(url: G.gitDir, children: gitTree)
            return rootNode.findChildren(predicate: searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 20) {
                List(searchResults, children: \.children) { node in
                    Text("\(node.name)")
                        .font(.system(size: 24))
                        .onTapGesture {
                            node.showPlaintext()
                        }
                        .swipeActions(allowsFullSwipe: false) {
                            Button(action: {
                                handleGitRemove(node: node)
                            }) {
                                Image(systemName: "xmark")
                            }
                            .tint(.red)
                        }
                }
                .searchable(text: $searchText)
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            handleGitSync()
                        } label: {
                            let systemName = Git.indexHasLocalChanges() ?
                                                        "icloud.and.arrow.up" :
                                                        "icloud.and.arrow.down"
                            Image(systemName: systemName).bold()
                        }
                    }

                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            G.logger.info("TODO")
                        } label: {
                            Image(systemName: "plus.circle").bold()
                        }
                    }

                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            if appState.identityIsUnlocked {
                                let _ = appState.lockIdentity()
                            } else {
                                let _ = appState.unlockIdentity(passphrase: "x")
                            }
                        } label: {
                            let systemName = appState.identityIsUnlocked ? "lock.open.fill" :
                                                                           "lock.fill"
                            Image(systemName: systemName).bold()
                        }
                    }

                    ToolbarItem(placement: .bottomBar) {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape.circle").bold()
                        }
                    }
                }
            }
        }
        .padding()
        .onAppear {
            if remote.isEmpty {
#if targetEnvironment(simulator)
                remote = "git://127.0.0.1/james"
#else
                remote = "git://10.0.1.8/james"
#endif
            }

            try? FileManager.default.removeItem(at: G.gitDir)
            Git.clone(remote: remote)
            loadGitTree()
        }
    }

    private func loadGitTree() {
        do {
            gitTree = (try PwNode.loadFrom(G.gitDir)).children ?? []
        } catch {
            G.logger.error("\(error)")
        }
    }

    private func handleGitSync() {
        if Git.indexHasLocalChanges() {
            let _ = Git.push()
        } else {
            let _ = Git.pull()
            loadGitTree()
        }
    }

    private func handleGitRemove(node: PwNode) {
        do {
            try FileManager.default.removeItem(at: node.url)
            let _ = Git.add(relativePath: ".")

        } catch {
            G.logger.error("\(error)")
        }
    }
}
