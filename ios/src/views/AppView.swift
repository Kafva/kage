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
                if !Git.repoIsInitialized() {
                    uninitializedTreeView
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
            // Ignore interactions when a background task is running
            .disabled(appState.backgroundTaskInProgress)
        }
    }

    private var uninitializedTreeView: some View {
        VStack(alignment: .center, spacing: 5) {
            Image(systemName: "rays")
                .font(G.title2Font)

            Text("Uninitialized password repoistory")
                .font(G.bodyFont)
        }
        .foregroundColor(.gray)
    }

    private var toolbarView: some View {
        let edgesSpacing = 20.0

        return HStack(spacing: 24) {
            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape")
            }
            .padding(.leading, edgesSpacing)

            NavigationLink(destination: PwNodeView(node: nil)) {
                Image(systemName: "plus.rectangle.portrait")
            }
            .disabled(!FileManager.default.isDir(G.gitDir))

            Spacer()

            Button {
                expandTree.toggle()
            } label: {
                let expandIconName =
                    expandTree
                    ? "rectangle.compress.vertical"
                    : "rectangle.expand.vertical"
                Image(systemName: expandIconName)
            }
            .disabled(!Git.repoIsInitialized())

            Button {
                handleLockIdentity()
            } label: {
                let systemName =
                    appState.identityIsUnlocked ? "lock.open" : "lock"
                Image(systemName: systemName)
            }
            .disabled(!Git.repoIsInitialized() || !appState.identityIsUnlocked)
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
        .padding(.bottom, 10)
    }

    private func handleGitPush() {
        appState.backgroundTaskInProgress = true
        #if targetEnvironment(simulator)
            let deadline: DispatchTime = .now() + 2
        #else
            let deadline: DispatchTime = .now()
        #endif

        // Delay for testing on simulator
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: deadline)
        {
            do {
                try Git.push()
                try appState.reloadGitTree()
                DispatchQueue.main.async {
                    currentError = nil
                    appState.backgroundTaskInProgress = false
                }
            }
            catch {
                DispatchQueue.main.async {
                    currentError = uiError("\(error.localizedDescription)")
                    appState.backgroundTaskInProgress = false
                }
            }
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
