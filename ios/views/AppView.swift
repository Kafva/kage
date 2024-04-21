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
    @State private var expandTree = false

    var body: some View {
        let width = showPlaintext ? 0.8*G.screenWidth : G.screenWidth
        let height = showPlaintext ? 0.3*G.screenHeight : G.screenHeight
        let opacity = 1.0

        NavigationStack {
            VStack {
                SearchView(searchText: $searchText)
                Spacer()
                if Git.repoIsEmpty() {
                    MessageView(type: .empty)

                } else {
                    TreeView(searchText: $searchText, 
                             targetNode: $targetNode,
                             showPwNode: $showPwNode, 
                             showPlaintext: $showPlaintext,
                             expandTree: $expandTree)
                }
                Spacer()
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
            .onAppear {
                do {
                    try appState.reloadGitTree()
                } catch {
                    G.logger.error("\(error)")
                }
            }
        }
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

         .gesture(DragGesture(minimumDistance: 10.0, coordinateSpace: .local)
             .onEnded { value in
                 // Dismiss on downward swipe motion
                 if value.translation.height  > 0 {
                     G.logger.debug("Dismissing overlay based on drag gesture")
                     dismiss()
                 }
             }
        )
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
            /* Settings */
            Button {
              withAnimation { showSettings = true }
            } label: {
                Image(systemName: "gearshape")
            }
            .padding(.leading, 20)

            /* New folder */
            Button {
                forFolder = true
                withAnimation { showPwNode = true }
            } label: {
                Image(systemName: "rectangle.stack.badge.plus")
            }
            .disabled(!FileManager.default.isDir(G.gitDir))

            /* New password */
            Button {
                forFolder = false
                withAnimation { showPwNode = true }
            } label: {
                Image(systemName: "rectangle.badge.plus")
            }
            .disabled(!FileManager.default.isDir(G.gitDir))

            Spacer()

            /* Expand/collapse tree */
            Button {
                expandTree.toggle() 
            } label: {
                let expandIconName = expandTree ? "rectangle.compress.vertical" :
                                                  "rectangle.expand.vertical"
                Image(systemName: expandIconName)
            }

            /* Lock indicator */
            Button {
                handleLockIdentity()
            } label: {
                let systemName =  appState.identityIsUnlocked ?
                                    "lock.open" : "lock"
                Image(systemName: systemName)
            }

            /* Sync status indicator */
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
}
