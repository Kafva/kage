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
    @State private var showNewFolder = false

    var body: some View {
        NavigationStack {
            listView
        }
        .overlay(OverlayView(showView: $showPlaintext,
                             contentWidth: 0.8 * G.screenWidth,
                             contentHeight: 0.3 * G.screenHeight) {
             PlaintextView(showPlaintext: $showPlaintext,
                           targetNode: $targetNode)
        })
        .overlay(OverlayView(showView: $showAuthentication,
                             contentWidth: 0.8 * G.screenWidth,
                             contentHeight: G.screenHeight) {
             AuthenticationView(showAuthentication: $showAuthentication,
                                showPlaintext: $showPlaintext)
        })
        .popover(isPresented: $showNewPassword) {
            PwNodeView(targetNode: $targetNode, forFolder: false)
        }
        .popover(isPresented: $showNewFolder) {
            PwNodeView(targetNode: $targetNode, forFolder: true)
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
                do {
                    try Git.clone(remote: remote)
                    try Git.configSetUser(username: "james")
                    try appState.reloadGitTree()
                } catch {
                    try? FileManager.default.removeItem(at: G.gitDir)
                    G.logger.error("\(error)")
                }
            }
        }
    }

    private var searchResults: [PwNode] {
        if searchText.isEmpty {
            return appState.rootNode.children ?? []
        } else {
            return appState.rootNode.findChildren(predicate: searchText)
        }
    }

    private var listView: some View {
        List(searchResults, children: \.children) { node in
            Text("\(node.name)")
                .font(.system(size: 18))
                .onTapGesture {
                    if !node.isLeaf {
                        return
                    }
                    targetNode = node
                    if !appState.identityIsUnlocked {
                        showAuthentication = true
                    } else {
                        showPlaintext = true
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
                if appState.hasLocalChanges {
                    Button {
                        handleGitPush()
                    } label: {
                        Image(systemName: "icloud.and.arrow.up.fill").bold().foregroundColor(.green)
                    }
                }
                Button {
                    showNewPassword = true
                } label: {
                    Image(systemName: "key").bold()
                }
                Button {
                    showNewFolder = true
                } label: {
                    Image(systemName: "folder.badge.plus").bold()
                }

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.circle").bold()
                }

                Button {
                    handleUnlockIdentity()
                } label: {
                    let systemName =  appState.identityIsUnlocked ?
                                        "lock.open.fill" : "lock.fill"
                    Image(systemName: systemName).bold()
                }
            }
        }
    }

    private func handleGitPush() {
        do {
            try Git.push()
            try appState.reloadGitTree()
        } catch {
            G.logger.error("\(error)")
        }
    }

    private func handleUnlockIdentity() {
        if appState.identityIsUnlocked {
            do {
                try appState.lockIdentity()
            } catch {
                G.logger.error("\(error)")
            }
        } else {
            showAuthentication = true
        }
    }

    private func handleGitRemove(node: PwNode) {
        do {
            try Git.rmCommit(node: node)
            try appState.reloadGitTree()

        } catch {
            G.logger.error("\(error)")
            try? Git.reset()
        }
    }
}

private struct OverlayView<Content: View>: View {
    @Binding var showView: Bool
    let contentWidth: CGFloat
    let contentHeight: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            if showView {
                Color(UIColor.systemBackground).opacity(0.8)
                content
                .frame(width: contentWidth, height: contentHeight)
            }
        }
        .ignoresSafeArea()
    }
}
