import SwiftUI

struct AppView: View {
    @EnvironmentObject var appState: AppState

    @State private var searchText = ""
    @State private var expandTree = false
    @State private var currentError: String?

    var body: some View {
        NavigationStack {
            VStack {
                SearchView(searchText: $searchText)
                    .padding(.top, 40)
                    .padding(.bottom, 10)
                Spacer()
                if Git.repoIsEmpty() {
                    emptyTreeView
                }
                else {
                    TreeView(
                        searchText: $searchText,
                        expandTree: $expandTree,
                        currentError: $currentError)
                }
                Spacer()
                toolbarView
            }
            // Do not move navigation bar items when the keyboard appears
            .ignoresSafeArea(.keyboard)
            .onAppear {
                if !FileManager.default.isDir(G.gitDir) {
                    return
                }

                do {
                    try appState.reloadGitTree()
                }
                catch {
                    currentError = uiError("\(error.localizedDescription)")
                }
            }
        }
    }

    private var emptyTreeView: some View {
        VStack(alignment: .center, spacing: 5) {
            Image(systemName: "rays")
                .font(G.title2Font)

            Text("Empty password repoistory")
                .font(G.bodyFont)
        }
        .foregroundColor(.gray)
    }

    private var toolbarView: some View {
        let edgesSpacing = 20.0

        return HStack(spacing: 24) {
            /* Settings */
            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape")
            }
            .padding(.leading, edgesSpacing)

            /* New password or folder */
            NavigationLink(destination: PwNodeView(node: nil)) {
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
                appState.localHeadMatchesRemote && currentError == nil
                    ? edgesSpacing : 0)

            if currentError != nil {
                NavigationLink(
                    destination: ErrorView(currentError: $currentError)
                ) {
                    Image(systemName: "exclamationmark.circle").foregroundColor(
                        G.errorColor)
                }
                .padding(.trailing, edgesSpacing)
            }
            else if !appState.localHeadMatchesRemote {
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

    private func handleGitPush() {
        do {
            try Git.push()
            try appState.reloadGitTree()
        }
        catch {
            currentError = uiError("\(error.localizedDescription)")
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
            currentError = uiError("\(error.localizedDescription)")
        }
    }
}
