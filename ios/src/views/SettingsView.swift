import OSLog
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showView: Bool

    @AppStorage("remote") private var remote: String = ""
    @State private var origin: String = ""
    @State private var reponame: String = ""
    @State private var showAlert: Bool = false
    @State private var inProgress: Bool = false

    private var remoteInfoTile: some View {
        Group {
            TileView(iconName: "server.rack") {
                TextField("Remote origin", text: $origin)
                    .onChange(of: origin, initial: false) { (_, _) in
                        submitRemote()
                    }
            }

            TileView(iconName: "text.book.closed") {
                TextField("Repository", text: $reponame)
                    .onChange(of: reponame, initial: false) { (_, _) in
                        submitRemote()
                    }
            }
        }
        .textFieldStyle(.plain)
        .onAppear {
            #if targetEnvironment(simulator)
                remote = "git://127.0.0.1/james.git"
            #elseif DEBUG
                remote = "git://10.0.77.1/jonas.git"
            #endif
            loadCurrentRemote()
        }
    }

    private var syncTile: some View {
        let iconName: String
        let text: String
        let isEmpty = Git.repoIsEmpty()

        if isEmpty {
            iconName = "square.and.arrow.down"
            text = "Fetch password repository"
        }
        else {
            iconName = "arrow.triangle.2.circlepath"
            text = "Reset password repository"
        }

        return TileView(iconName: iconName) {
            Button {
                if isEmpty {
                    Task {
                        inProgress = true
                        #if targetEnvironment(simulator)
                            try? await Task.sleep(nanoseconds: 2000_000_000)
                        #endif
                        handleGitClone()
                        inProgress = false
                    }
                }
                else {
                    showAlert = true
                }
            } label: {
                if inProgress {
                    Text("Loading...")
                }
                else {
                    Text(text).lineLimit(1)
                        .foregroundColor(G.accentColor)
                }
            }
            .alert("Replace all local data?", isPresented: $showAlert) {
                Button("Yes", role: .destructive) {
                    Task {
                        inProgress = true
                        #if targetEnvironment(simulator)
                            try? await Task.sleep(nanoseconds: 2000_000_000)
                        #endif
                        handleGitClone()
                        inProgress = false
                    }
                }
            }
            .disabled(!validRemote || inProgress)
        }
    }

    private var versionTile: some View {
        TileView(iconName: nil) {
            Text(G.gitVersion).font(G.captionFont)
                .foregroundColor(.gray)
                .frame(alignment: .leading)
        }
    }

    private var errorTile: some View {
        TileView(iconName: "exclamationmark.circle") {
            Text(appState.currentError ?? "Unknown error").font(G.captionFont)
                .foregroundColor(G.errorColor)
                .frame(alignment: .leading)
        }
        .onTapGesture { appState.currentError = nil }
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
                if appState.currentError != nil {
                    errorTile
                }
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
            && (try? regex.firstMatch(in: reponame) != nil) ?? false
    }

    private func submitRemote() {
        let newRemote = "git://\(origin)/\(reponame)"
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
        reponame = String(remote[nameStart...])
        G.logger.debug("Loaded remote: git://\(origin)/\(reponame)")
    }

    private func handleGitClone() {
        if !validRemote {
            appState.uiError("Refusing to clone from invalid remote: \(remote)")
            return
        }

        try? FileManager.default.removeItem(at: G.gitDir)
        do {
            try Git.clone(remote: remote)
            try Git.configSetUser(username: reponame)
            try appState.reloadGitTree()
        }
        catch {
            try? FileManager.default.removeItem(at: G.gitDir)
            appState.uiError("\(error.localizedDescription)")
        }
    }
}
