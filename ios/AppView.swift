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

struct AppView: View {
    @AppStorage("remote") private var remote: String = ""

    @EnvironmentObject var appState: AppState

    @State private var searchText = ""

    @State private var targetNode: PwNode?

    @State private var showAuthentication: Bool = false
    @State private var showPlaintext: Bool = false
    @State private var showSettings = false
    @State private var showNewPassword = false


    @State private var plaintext: String = ""
    @State private var passphrase: String = ""

    var searchResults: [PwNode] {
        if searchText.isEmpty {
            return appState.rootNode.children ?? []
        } else {
            return appState.rootNode.findChildren(predicate: searchText)
        }
    }

    private func handleShowPlaintext() {
        guard let targetNode else {
            G.logger.debug("No target node set")
            return
        }
        guard let value = targetNode.getPlaintext() else {
            G.logger.error("Failed to retrieve plaintext")
            return
        }
        plaintext = value
        showAuthentication = false
        showPlaintext = true
    }

    private var listView: some View {
        // Two buttons at the bottom of each folder for add pw/folder
        List(searchResults, children: \.children) { node in
            Text("\(node.name)")
                .font(.system(size: 18))
                .onTapGesture {
                    targetNode = node
                    if !appState.identityIsUnlocked {
                        showAuthentication = true
                    } else {
                        handleShowPlaintext()
                    }
                }
                .swipeActions(allowsFullSwipe: false) {
                    Button(action: {
                        handleGitRemove(node: node)
                    }) {
                        Image(systemName: "xmark.circle")
                    }
                    .tint(.red)
                }
        }
        .searchable(text: $searchText)
        .listStyle(.plain)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                // TODO: only show when index is dirty and can't connect to
                // server
                // TODO use appstate
                if Git.indexHasLocalChanges() {
                    Button {
                        let _ = Git.push()
                    } label: {
                        Image(systemName: "icloud.and.arrow.up.fill").bold().foregroundColor(.green)
                    }
                }
                Button {
                    showNewPassword = true
                } label: {
                    Image(systemName: "plus.circle").bold()
                }
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.circle").bold()
                }

                Button {
                    if appState.identityIsUnlocked {
                        let _ = appState.lockIdentity()
                    } else {
                        showAuthentication = true
                    }
                } label: {
                    let systemName =  appState.identityIsUnlocked ?
                                        "lock.open.fill" : "lock.fill"
                    Image(systemName: systemName).bold()
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            listView
        }
        .alert("", isPresented: $showPlaintext) {
            // TODO folders should not trigger unlockIdentity
            // TODO do not use an alert for this...
            Text("\(targetNode?.name ?? "Plaintext")")
            Text(plaintext).bold().monospaced().foregroundColor(.black)
            //Text(" ")
            Button("Close", role: .cancel) {
                showPlaintext = false
            }
        }
        .alert("Authentication required", isPresented: $showAuthentication) {
            SecureField("", text: $passphrase)

            Button("Submit") {
                if !appState.unlockIdentity(passphrase: passphrase) {
                    G.logger.debug("Incorrect password")
                    return
                }
                handleShowPlaintext()
            }
        }
        .popover(isPresented: $showNewPassword) {
            NewPasswordView(targetNode: $targetNode)
        }
        .popover(isPresented: $showSettings) { SettingsView() }
        .onAppear {
#if DEBUG && targetEnvironment(simulator)
            remote = "git://127.0.0.1/james"
#elseif DEBUG
            remote = "git://10.0.1.8/james"
#endif
            if !remote.isEmpty {
                try? FileManager.default.removeItem(at: G.gitDir)
                Git.clone(remote: remote)
                appState.loadGitTree()
            }
        }
    }


    private func handleGitRemove(node: PwNode) {
        do {
            try FileManager.default.removeItem(at: node.url)
            let relativePath = node.url.path()
                                       .trimmingPrefix(G.gitDir.path() + "/")
            let _ = Git.add(relativePath: String(relativePath))

        } catch {
            G.logger.error("\(error)")
        }
    }
}
