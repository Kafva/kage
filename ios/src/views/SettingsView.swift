import OSLog
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showView: Bool

    @AppStorage("remote") private var remote: String = ""
    @State private var origin: String = ""
    @State private var username: String = ""
    @State private var showAlert: Bool = false
    @State private var inProgress: Bool = false
    @State private var cloneError: String?

    private var remoteInfoTile: some View {
        Group {
            TileView(iconName: "server.rack") {
                TextField("Remote origin", text: $origin)
                    .onChange(of: origin, initial: false) { (_, _) in
                        submitRemote()
                    }
            }

            TileView(iconName: "person.crop.circle") {
                TextField("Username", text: $username)
                    .onChange(of: username, initial: false) { (_, _) in
                        submitRemote()
                    }
            }
        }
        .textFieldStyle(.plain)
        .onAppear {
            #if targetEnvironment(simulator)
                remote = "git://127.0.0.1/james"
            #else
                remote = "git://10.0.1.8/james"
            #endif
            loadCurrentRemote()
        }
    }

    private var syncTile: some View {
        let iconName: String
        let text: String
        let iconColor: Color
        let isEmpty = Git.repoIsEmpty()

        if let cloneError {
            iconName =
                isEmpty
                ? "square.and.arrow.down"
                : "exclamationmark.arrow.triangle.2.circlepath"
            text = cloneError
            iconColor = G.errorColor

        }
        else if isEmpty {
            iconName = "square.and.arrow.down"
            text = "Fetch password repository"
            iconColor = .accentColor

        }
        else {
            iconName = "exclamationmark.arrow.triangle.2.circlepath"
            text = "Reset password repository"
            iconColor = .accentColor
        }

        return Group {
            if inProgress {
                // TODO does not work?
                ProgressView()
            }
            else {
                TileView(iconName: iconName) {
                    Button {
                        if cloneError != nil {
                            // Dismiss error
                            self.cloneError = nil
                        }
                        else if isEmpty {
                            handleGitClone()
                        }
                        else {
                            showAlert = true
                        }
                    } label: {
                        Text(text).lineLimit(1)
                            .foregroundColor(iconColor)
                    }
                    .alert("Replace all local data?", isPresented: $showAlert) {
                        Button("Yes", role: .destructive) {
                            handleGitClone()
                        }
                    }
                    .disabled(!validRemote)
                }
            }
        }
    }

    private var versionTile: some View {
        TileView(iconName: nil) {
            Text(G.gitVersion).font(G.captionFont)
                .foregroundColor(.gray)
                .frame(alignment: .leading)
        }
    }

    private var historyTile: some View {
        TileView(iconName: "app.connected.to.app.below.fill") {
            NavigationLink(destination: HistoryView()) {
                Text("History").foregroundColor(.accentColor)
            }
            .disabled(Git.repoIsEmpty())
        }
    }

    private var passwordCountTile: some View {
        let passwords = try? FileManager.default.findFiles(G.gitDir)
        return TileView(iconName: nil) {
            if let passwords {
                Text("Storage: \(passwords.count) password(s)")
                    .font(G.captionFont)
                    .foregroundColor(.gray)
                    .frame(alignment: .leading)
            }
            else {
                EmptyView()
            }
        }
    }

    var body: some View {
        let settingsHeader = Text("Settings").font(G.title3Font)
            .padding(.bottom, 10)
            .padding(.top, 20)
            .textCase(nil)
        Form {
            Section(header: settingsHeader) {
                remoteInfoTile
                syncTile
                historyTile
                passwordCountTile
                versionTile
            }

            Section {
                Button(action: dismiss) {
                    Text("Dismiss").font(G.bodyFont)
                }
                .padding([.top, .bottom], 5)
            }
        }
        .formStyle(.grouped)
    }

    private func dismiss() {
        withAnimation { showView = false }
    }

    private var validRemote: Bool {
        let regex = /[-_.a-z0-9]{5,64}/
        return (try? regex.firstMatch(in: origin) != nil) ?? false
            && (try? regex.firstMatch(in: username) != nil) ?? false
    }

    private func submitRemote() {
        let newRemote = "git://\(origin)/\(username)"
        if validRemote {
            if remote == newRemote {
                return
            }
            remote = newRemote
            G.logger.debug("Updated remote: \(remote)")
        }
        else {
            G.logger.debug("Invalid remote: \(newRemote)")
        }
    }

    private func loadCurrentRemote() {
        if remote.isEmpty {
            return
        }
        guard let idx = remote.lastIndex(of: "/") else {
            return
        }
        if idx == remote.startIndex || idx == remote.endIndex {
            G.logger.debug("Invalid remote origin: \(remote)")
            return
        }

        let originStart = remote.index(
            remote.startIndex, offsetBy: "git://".count)
        let originEnd = remote.index(before: idx)
        let nameStart = remote.index(after: idx)

        origin = String(remote[originStart...originEnd])
        username = String(remote[nameStart...])
        G.logger.debug("Loaded remote: git://\(origin)/\(username)")
    }

    private func handleGitClone() {
        if !validRemote {
            appState.uiError("Refusing to clone from invalid remote: \(remote)")
            return
        }

        inProgress = true
        try? FileManager.default.removeItem(at: G.gitDir)
        do {
            try Git.clone(remote: remote)
            try Git.configSetUser(username: username)
            try appState.reloadGitTree()
        }
        catch {
            try? FileManager.default.removeItem(at: G.gitDir)
            appState.uiError("\(error.localizedDescription)")
            cloneError = error.localizedDescription
        }
        inProgress = false
    }
}
