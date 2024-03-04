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
            let rootNode = PwNode(url: GIT_DIR, children: gitTree)
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
                            node.show()
                        }
                }
                .searchable(text: $searchText)
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            let _ = Git.pull(GIT_DIR)
                        } label: {
                            Image(systemName: "arrow.down.circle").bold()
                        }
                    }
                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            LOGGER.info("TODO")
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
            do {
                try? FileManager.default.removeItem(at: GIT_DIR)
                Git.clone(remote: remote,  into: GIT_DIR)
                gitTree = (try PwNode.loadChildren(GIT_DIR)).children ?? []

            } catch {
                LOGGER.error("\(error)")
            }
        }
    }
}
