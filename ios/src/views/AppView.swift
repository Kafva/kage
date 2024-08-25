import SwiftUI

struct AppView: View {
    @EnvironmentObject var appState: AppState

    @State private var searchText = ""

    @State private var currentPwNode: PwNode?

    @State private var showSettings = false
    @State private var showErrors = false
    @State private var showPwNode = false
    @State private var showPlaintext = false
    @State private var expandTree = false

    var body: some View {
        let width = showPlaintext ? 0.8 * G.screenWidth : G.screenWidth
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
                        currentPwNode: $currentPwNode,
                        showPwNode: $showPwNode,
                        showPlaintext: $showPlaintext,
                        expandTree: $expandTree)
                }
                Spacer()
                toolbarView
            }
            // Do not move navigation bar items when the keyboard appears
            .ignoresSafeArea(.keyboard)
            .overlay(
                Group {
                    if showSettings || showErrors || showPwNode || showPlaintext
                    {
                        Color(UIColor.systemBackground)
                        overlayView
                            .frame(width: width, height: G.screenHeight)
                            .transition(.move(edge: .bottom))
                    }
                }
            )
            .onAppear {
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
                if currentPwNode != nil {
                    /* Edit view */
                    PwNodeView(
                        showView: $showPwNode,
                        currentPwNode: $currentPwNode)
                }
                else {
                    /* New password or folder view */
                    PwNodeView(
                        showView: $showPwNode,
                        currentPwNode: $currentPwNode)
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
                    currentPwNode: $currentPwNode)
            }
            else {
                /* Password entry */
                AuthenticationView(showView: $showPlaintext)
            }
        }
        // Disable default background for `Form`
        .scrollContentBackground(.hidden)
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

            if appState.currentError != nil {
                /* Error status indicator */
                Button {
                    withAnimation { showErrors = true }
                } label: {
                    Image(systemName: "exclamationmark.circle").foregroundColor(
                        G.errorColor)
                }
                .padding(.trailing, edgesSpacing)
            }
            else if appState.hasLocalChanges {
                /* Sync status indicator */
                Button {
                    handleGitPush()
                } label: {
                    Image(systemName: "square.and.arrow.up").foregroundColor(
                        .green)
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
            self.currentPwNode = nil
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
