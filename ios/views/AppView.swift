import SwiftUI
import OSLog

struct AppView: View {
    @AppStorage("remote") private var remote: String = ""

    @EnvironmentObject var appState: AppState

    @State private var searchText = ""

    @State private var targetNode: PwNode?
    @State private var forFolder = false

    @State private var showSettings = false
    @State private var showPwNode = false
    @State private var showPlaintext = false

    var body: some View {
        let width = showPlaintext ? 0.8*G.screenWidth : G.screenWidth
        let height = showPlaintext ? 0.3*G.screenHeight : G.screenHeight
        let opacity = showPlaintext ? 0.9 : 1.0

        NavigationStack {
            VStack {
                searchView
                listView
                toolbarView
            }
            .overlay(
                Group {
                    if showSettings || showPwNode || showPlaintext {
                        Color(UIColor.systemBackground).opacity(opacity)
                        overalyView
                        .frame(width: width, height: height)
                        .transition(.move(edge: .bottom))
                    }
                }
            )
        }
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

    private var searchView: some View {
        let background = RoundedRectangle(cornerRadius: 5)
                            .fill(G.textFieldBgColor)

        return TextField("Search",
                  text: $searchText)
        .multilineTextAlignment(.center)
        .font(.system(size: 18))
        .frame(width: G.screenWidth*0.7)
        // Padding inside the textbox
        .padding([.leading, .trailing], 5)
        .padding([.bottom, .top], 5)
        .background(background)
        // Padding outside the textbox
        .overlay(Group {
            // Clear content button
            if !searchText.isEmpty {
                HStack {
                    Spacer()
                    Button {
                        searchText = ""
                    } label: {
                      Image(systemName: "multiply.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 15))
                    }
                    .padding(.bottom, 30)
                }
            }
        })
    }

    private var overalyView: some View {
         Group {
             if showPwNode {
                 if let targetNode {
                    /* Edit view */
                    PwNodeView(showView: $showPwNode,
                               targetNode: $targetNode,
                               forFolder: targetNode.isDir)
                 }
                 else {
                    /* New password or folder view */
                    PwNodeView(showView: $showPwNode,
                               targetNode: $targetNode,
                               forFolder: forFolder)
                 }
             }
             else if showSettings {
                 /* Settings view */
                 SettingsView(showView: $showSettings)
             }
             else if appState.identityIsUnlocked {
                 /* Password in plaintext */
                 PlaintextView(showView: $showPlaintext,
                               targetNode: $targetNode)
             } else {
                 /* Password entry */
                 AuthenticationView(showView: $showPlaintext)
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
                    withAnimation {
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

                    Button(action: {
                        targetNode = node
                        withAnimation {
                            showPwNode = true
                        }
                    }) {
                        Image(systemName: "pencil")
                    }
                    .tint(.blue)

                }
        }
        .listStyle(.plain)
    }

    private var toolbarView: some View {
        HStack(spacing: 30) {
            if appState.hasLocalChanges {
                Button {
                    handleGitPush()
                } label: {
                    let systemName = appState.vpnActive ? "icloud.and.arrow.up.fill" :
                                                          "exclamationmark.icloud"
                    let color = appState.vpnActive ? Color.green :
                                                     Color.gray
                    Image(systemName: systemName).bold().foregroundColor(color)
                }
                .disabled(!appState.vpnActive)
            }
            Button {
                forFolder = false
                withAnimation { showPwNode = true }
            } label: {
                Image(systemName: "rectangle.badge.plus").bold()
            }
            Button {
                forFolder = true
                withAnimation { showPwNode = true }
            } label: {
                Image(systemName: "rectangle.stack.badge.plus").bold()
            }

            Button {
              withAnimation { showSettings = true }
            } label: {
                Image(systemName: "gearshape.circle").bold()
            }

            Button {
                handleLockIdentity()
            } label: {
                let systemName =  appState.identityIsUnlocked ?
                                    "lock.open.fill" : "lock.fill"
                Image(systemName: systemName).bold()
            }
        }
        .font(.system(size: 20))

    }

    private func handleGitPush() {
        do {
            try Git.push()
            try appState.reloadGitTree()
        } catch {
            G.logger.error("\(error)")
        }
    }

    private func handleLockIdentity() {
        if !appState.identityIsUnlocked {
            return
        }
        do {
            try appState.lockIdentity()
        } catch {
            G.logger.error("\(error)")
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
