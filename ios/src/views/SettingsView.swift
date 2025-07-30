import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @AppStorage("repoPath") private var repoPathStore: String = ""
    @AppStorage("remoteAddress") private var remoteAddressStore: String = ""
    @State private var remoteAddress: String = ""
    @State private var repoPath: String = ""
    @State private var showAlert: Bool = false
    @State private var currentError: String?

    var body: some View {
        Form {
            Section(header: Text("Settings").formHeaderStyle()) {
                remoteInfoTile
                syncTile
                historyTile
                passwordCountTile
                versionTile
                if currentError != nil {
                    ErrorTileView(currentError: $currentError).listRowSeparator(
                        .hidden)
                }

                HStack {
                    Button("Dismiss") {
                        hideKeyboard()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .padding(.leading, 5)

                    Spacer()

                    Button("Save") {
                        handleSubmit()
                    }
                    .buttonStyle(.bordered)
                    .tint(.accentColor)
                    .disabled(
                        repoPathStore == repoPath
                            && remoteAddressStore == remoteAddress
                    )
                    .padding(.trailing, 5)
                }
                .padding(.top, 40)
            }

        }
        .formStyle(.grouped)
        .navigationBarHidden(true)
        .onAppear {
            #if targetEnvironment(simulator)
                LOG.debug("Configuring preset remote")
                remoteAddressStore = "127.0.0.1"
                repoPathStore = "james.git"
            #endif
            // Load values from @AppStorage
            remoteAddress = remoteAddressStore
            repoPath = repoPathStore
        }
        // Ignore interactions when a background task is running
        .disabled(appState.backgroundTaskInProgress)
    }

    private var remoteInfoTile: some View {
        Group {
            TileView(iconName: "server.rack") {
                TextField("Remote address", text: $remoteAddress)
                    .textContentType(.oneTimeCode)
            }

            TileView(iconName: "text.book.closed") {
                TextField("Repository", text: $repoPath)
                    .textContentType(.oneTimeCode)
            }
        }
        .textFieldStyle(.plain)
    }

    private var syncTile: some View {
        let iconName: String
        let text: String
        let isInitialized = Git.repoIsInitialized()

        if !isInitialized {
            iconName = "square.and.arrow.down"
            text = String(localized: "Fetch password repository")
        }
        else {
            iconName = "arrow.triangle.2.circlepath"
            text = String(localized: "Reset password repository")
        }

        return TileView(iconName: iconName) {
            Button {
                hideKeyboard()
                if !isInitialized {
                    handleGitClone()
                }
                else {
                    showAlert = true
                }
            } label: {
                if appState.backgroundTaskInProgress {
                    Text("Loading…")
                }
                else {
                    Text(text).lineLimit(1)
                        .foregroundColor(ACCENT_COLOR)
                }
            }
            .alert("Replace all local data?", isPresented: $showAlert) {
                Button("Yes", role: .destructive) {
                    hideKeyboard()
                    handleGitClone()
                }
            }
            .disabled(!remoteIsValid)
        }
    }

    private var versionTile: some View {
        TileView(iconName: nil) {
            Text(GIT_VERSION).font(CAPTION_FONT)
                .foregroundColor(.gray)
                .frame(alignment: .leading)
        }
    }

    private var historyTile: some View {
        TileView(iconName: "app.connected.to.app.below.fill") {
            NavigationLink(destination: HistoryView()) {
                Text("History").foregroundColor(.accentColor)
            }
            .disabled(!Git.repoIsInitialized())
        }
    }

    private var passwordCountTile: some View {
        let passwords = try? FileManager.default.findFiles(GIT_DIR)
        let count = passwords?.count ?? 0
        return TileView(iconName: nil) {
            Text(String(localized: "Storage: \(count) password"))
                .font(CAPTION_FONT)
                .foregroundColor(.gray)
                .frame(alignment: .leading)
        }
    }

    private var remoteIsValid: Bool {
        let regexRemoteAddress = /^[-.A-Za-z0-9]{5,64}$/
        let regexRepoPath = /^[-_\/.@A-Za-z0-9]{5,64}$/

        guard let match = try? regexRemoteAddress.firstMatch(in: remoteAddress)
        else {
            return false
        }
        if match.first == nil {
            return false
        }

        guard let match = try? regexRepoPath.firstMatch(in: repoPath) else {
            return false
        }
        if match.first == nil {
            return false
        }

        return true
    }

    private var remote: String {
        "git://\(remoteAddress)/\(repoPath)"
    }

    private func handleSubmit() {
        if remoteAddress == remoteAddressStore && repoPath == repoPathStore {
            return
        }
        if !remoteIsValid {
            currentError = uiError("Invalid format for remote")
            return
        }

        remoteAddressStore = remoteAddress
        repoPathStore = repoPath
        LOG.info("Updated remote: \(remote)")
        currentError = nil
    }

    private func handleGitClone() {
        if !remoteIsValid {
            currentError = uiError(
                "Refusing to clone from invalid remote: \(remote)")
            return
        }

        #if targetEnvironment(simulator)
            let deadline: DispatchTime = .now() + 2
        #else
            let deadline: DispatchTime = .now()
        #endif

        appState.backgroundTaskInProgress = true
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: deadline)
        {
            do {

                try? FileManager.default.removeItem(atPath: GIT_DIR.string)
                try Git.clone(remote: remote)
                try Git.configSetUser(username: repoPath)

                DispatchQueue.main.async { @MainActor in
                    do {
                        try appState.reloadGitTree()
                        // Clear out any prior errors
                        currentError = nil
                    }
                    catch {
                        currentError = uiError("\(error.localizedDescription)")
                    }
                    appState.backgroundTaskInProgress = false
                }
            }
            catch {
                try? FileManager.default.removeItem(atPath: GIT_DIR.string)
                DispatchQueue.main.async { @MainActor in
                    currentError = uiError("\(error.localizedDescription)")
                    appState.backgroundTaskInProgress = false
                }
            }
        }
    }
}
