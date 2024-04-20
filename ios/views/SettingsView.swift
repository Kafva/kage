import SwiftUI
import OSLog


struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showView: Bool

    @AppStorage("remote") private var remote: String = ""
    @State private var origin: String = ""
    @State private var name: String = ""
    @State private var showAlert: Bool = false


    private var remoteInfoTile: some View {
        Group {
            TileView(iconName: "server.rack") {
                TextField("Remote origin", text: $origin)
            }

            TileView(iconName: "person.crop.circle") {
                TextField("Username", text: $name)
            }
        }
        .textFieldStyle(.roundedBorder)
        .onSubmit {
            if !origin.isEmpty && !name.isEmpty {
                remote = "git://\(origin)/\(name)"
            }
        }
        .onAppear {
            loadCurrentRemote()
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
            G.logger.debug("invalid remote origin: \(remote)")
            return
        }

        let originStart = remote.index(remote.startIndex, offsetBy: "git://".count) 
        let originEnd = remote.index(before: idx)
        let nameStart = remote.index(after: idx)

        origin = String(remote[originStart...originEnd])
        name = String(remote[nameStart...])
    }

    private var syncTile: some View {
        let iconName: String
        let text: String
        let isEmpty = (try? FileManager.default.ls(G.gitDir).isEmpty) ?? true
        G.logger.debug("\((try? FileManager.default.ls(G.gitDir)) ?? [])")

        if isEmpty {
            iconName = "square.and.arrow.down"
            text = "Fetch password repository"

        } else {
            iconName = "exclamationmark.arrow.triangle.2.circlepath"
            text = "Reset password repository"
        }

        return TileView(iconName: iconName) {
            Button {
                if isEmpty {
                    handleGitClone()
                } else {
                    showAlert = true
                }
            } label: {
                Text(text)
            }
            .alert("Replace all local data?", isPresented: $showAlert) {
                Button("Yes", role: .destructive) {
                    handleGitClone()
                }
            }
        }
    }
    private var versionTile: some View {
        TileView(iconName: nil, text: "Version") {
            Text(G.gitVersion).font(.system(size: 12))
                              .foregroundColor(.gray)
        }

    }

    // remote address
    // re-sync from scratch
    // version
    // debugging: force offline/online
    // History (git log) view
    var body: some View {
        Form {
            let settingsHeader = Text("Settings").font(G.headerFont)
                                                 .padding(.bottom, 10)
                                                 .padding(.top, 20)
                                                 .textCase(nil)


            Section(header: settingsHeader) {
                remoteInfoTile
                syncTile

            }

            Section {
                Button(action: { withAnimation { showView = false } } ) {
                    Text("Dismiss").bold().font(.system(size: 18))
                }
                .padding([.top, .bottom], 5)
            }
        }
    }


    private func handleGitClone() {
        #if targetEnvironment(simulator)
            remote = "git://127.0.0.1/james"
        #else
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

