import OSLog
import SwiftUI

struct AppView: View {
    @EnvironmentObject var appState: AppState

    @State private var searchText = ""

    @State private var targetNode: PwNode?

    @State private var showSettings = false
    @State private var showErrors = false
    @State private var showPwNode = false
    @State private var showPlaintext = false
    @State private var expandTree = false

    var body: some View {
        let width = showPlaintext ? 0.8 * G.screenWidth : G.screenWidth
        let height = showPlaintext ? 0.3 * G.screenHeight : G.screenHeight
        let opacity = 0.97

        NavigationStack {
            VStack {
                SearchView(searchText: $searchText)
                    .padding(.top, 40)
                    .padding(.bottom, 10)
                Spacer()
                if Git.repoIsEmpty() {
                    MessageView(type: .empty)
                }
                else {
                    TreeView(
                        searchText: $searchText,
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
                    if showSettings || showErrors || showPwNode || showPlaintext
                    {
                        Color(UIColor.systemBackground).opacity(opacity)
                        overlayView
                            .frame(width: width, height: height)
                            .transition(.move(edge: .bottom))
                    }
                }
            )
            .onAppear {
                // TODO: tmp
                appState.uiError(
                    "If you display text that’s associated with a point in space, such as a label for a 3D object, you generally want to use billboarding"
                )
                if !FileManager.default.isDir(G.gitDir) {
                    return
                }

                do {
                    try appState.reloadGitTree()
                }
                catch {
                    appState.uiError("\(error.localizedDescription)")
                }
            }
        }
    }

    private var overlayView: some View {
        VStack {
            if showPwNode {
                if targetNode != nil {
                    /* Edit view */
                    PwNodeView(
                        showView: $showPwNode,
                        targetNode: $targetNode)
                }
                else {
                    /* New password or folder view */
                    PwNodeView(
                        showView: $showPwNode,
                        targetNode: $targetNode)
                }
            }
            else if showSettings {
                /* Settings view */
                SettingsView(showView: $showSettings)
            }
            else if showErrors {
                /* Error description view */
                ErrorView(showView: $showErrors)
            }
            else if appState.identityIsUnlocked {
                /* Password in plaintext */
                PlaintextView(
                    showView: $showPlaintext,
                    targetNode: $targetNode)
            }
            else {
                /* Password entry */
                AuthenticationView(showView: $showPlaintext)
            }
        }
        // Disable default background for `Form`
        .scrollContentBackground(.hidden)
        .padding([.top, .bottom], 100)
    }

    private var toolbarView: some View {
        let edgesSpacing = 20.0

        return HStack(spacing: 15) {
            /* Settings */
            Button {
                withAnimation { showSettings = true }
            } label: {
                Image(systemName: "gearshape")
            }
            .padding(.leading, edgesSpacing)

            /* New password or folder */
            Button {
                withAnimation { showPwNode = true }
            } label: {
                Image(systemName: "plus.rectangle.portrait")
            }
            .disabled(!FileManager.default.isDir(G.gitDir))

            Spacer()

            /* Expand/collapse tree */
            Button {
                expandTree.toggle()
            } label: {
                let expandIconName =
                    expandTree
                    ? "rectangle.compress.vertical"
                    : "rectangle.expand.vertical"
                Image(systemName: expandIconName)
            }
            .disabled(Git.repoIsEmpty())

            /* Lock indicator */
            Button {
                handleLockIdentity()
            } label: {
                let systemName =
                    appState.identityIsUnlocked ? "lock.open" : "lock"
                Image(systemName: systemName)
            }
            .disabled(Git.repoIsEmpty())
            // Add trailing padding if both sync and error are hidden
            .padding(
                .trailing,
                !appState.hasLocalChanges && appState.currentError == nil
                    ? edgesSpacing : 0)

            if appState.hasLocalChanges {
                /* Sync status indicator */
                Button {
                    handleGitPush()
                } label: {
                    Image(systemName: "square.and.arrow.up").foregroundColor(
                        .green)
                }
                .padding(.trailing, edgesSpacing)
            }
            else if appState.currentError != nil {
                /* Error status indicator */
                Button {
                    withAnimation { showErrors = true }
                } label: {
                    Image(systemName: "exclamationmark.circle").foregroundColor(
                        G.errorColor)
                }
                .padding(.trailing, edgesSpacing)
            }
        }
        .font(G.toolbarIconFont)
    }

    private func dismiss() {
        withAnimation {
            self.showSettings = false
            self.showErrors = false
            self.showPwNode = false
            self.showPlaintext = false
            self.targetNode = nil
        }
    }

    private func handleGitPush() {
        do {
            try Git.push()
            try appState.reloadGitTree()
        }
        catch {
            appState.uiError("\(error.localizedDescription)")
        }
    }

    private func handleLockIdentity() {
        if !appState.identityIsUnlocked {
            return
        }
        do {
            try appState.lockIdentity()
        }
        catch {
            appState.uiError("\(error.localizedDescription)")
        }
    }
}
