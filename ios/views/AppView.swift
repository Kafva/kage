import SwiftUI
import OSLog

struct AppView: View {
    @EnvironmentObject var appState: AppState

    @State private var searchText = ""

    @State private var targetNode: PwNode?
    @State private var forFolder = false

    @State private var showSettings = false
    @State private var showPwNode = false
    @State private var showPlaintext = false

    private var searchResults: [PwNode] {
        if searchText.isEmpty {
            return appState.rootNode.children ?? []
        } else {
            return appState.rootNode.findChildren(predicate: searchText)
        }
    }

    var body: some View {
        let width = showPlaintext ? 0.8*G.screenWidth : G.screenWidth
        let height = showPlaintext ? 0.3*G.screenHeight : G.screenHeight
        let opacity = showPlaintext ? 0.9 : 1.0

        NavigationStack {
            VStack {
                searchView
                outlineGroupView
                // PwNodeTreeView(searchText: $searchText)
                // listView
                toolbarView
            }
            .overlay(
                Group {
                    if showSettings || showPwNode || showPlaintext {
                        Color(UIColor.systemBackground).opacity(opacity)
                        overlayView
                        .frame(width: width, height: height)
                        .transition(.move(edge: .bottom))
                    }
                }
            )
        }
    }

    private var searchView: some View {
        let background = RoundedRectangle(cornerRadius: 5)
                            .fill(G.textFieldBgColor)

        return TextField("Search", text: $searchText)
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
                        .padding(.trailing, 5)
                    }
                }
            }
        })
    }

    private var overlayView: some View {
         VStack {
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
         // Disable default background for `Form`
         .scrollContentBackground(.hidden)
         .padding([.top, .bottom], 100)

         .gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
             .onEnded { value in
                 // Dismiss on downward swipe motion
                 if value.translation.height  > 0 {
                     dismiss()
                 }
             }
        )
    }

    private var listView: some View {
        List(searchResults, children: \.children) { node in
            Text(node.name)
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

    // TODO: https://developer.apple.com/documentation/swiftui/disclosuregroupstyle
    private var outlineGroupView: some View {
        OutlineGroup(searchResults, children: \.children) { node in
            Text(node.name)
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
    }

    private var toolbarView: some View {
        let syncIconName: String
        let color: Color

        if appState.hasLocalChanges {
            if appState.vpnActive {
                syncIconName = "square.and.arrow.up"
                color = Color.green

            } else {
                syncIconName = "square.and.arrow.up.trianglebadge.exclamationmark"
                color = Color.gray
            }
        } else {
            syncIconName = "checkmark.circle"
            color = Color.gray
        }

        return HStack(spacing: 10) {
            Button {
                forFolder = false
                withAnimation { showPwNode = true }
            } label: {
                Image(systemName: "rectangle.badge.plus")
            }
            .padding(.leading, 20)
            .disabled(!FileManager.default.isDir(G.gitDir))

            Button {
                forFolder = true
                withAnimation { showPwNode = true }
            } label: {
                Image(systemName: "rectangle.stack.badge.plus")
            }
            .disabled(!FileManager.default.isDir(G.gitDir))

            Button {
              withAnimation { showSettings = true }
            } label: {
                Image(systemName: "gearshape")
            }

            Spacer()

            Button {
                handleLockIdentity()
            } label: {
                let systemName =  appState.identityIsUnlocked ?
                                    "lock.open" : "lock"
                Image(systemName: systemName)
            }

            Button {
                handleGitPush()
            } label: {
                Image(systemName: syncIconName).foregroundColor(color)
            }
            .disabled(!appState.vpnActive || !appState.hasLocalChanges)
            .padding(.trailing, 20)
        }
        .font(.system(size: 20))
    }

    private func dismiss() {
        withAnimation { 
            self.forFolder = false
            self.showSettings = false
            self.showPwNode = false
            self.showPlaintext = false
            self.targetNode = nil
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
