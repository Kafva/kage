import SwiftUI
import OSLog


struct SettingsView: View {
    @AppStorage("remote") private var remote: String = ""

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("Clone").onTapGesture {
                // TODO progress view
                try? FileManager.default.removeItem(at: G.gitDir)
                Git.clone(remote: remote, into: G.gitDir);
            }

            Text("Pull").onTapGesture {
                Git.pull(G.gitDir);
            }

            Text("Encrypt").onTapGesture {
                let recipient = G.gitDir.appending(path: ".age-recipients")
                let outpath = G.gitDir.appending(path: "iOS.age")
                let _ = Age.encrypt(recipient: recipient,
                                    outpath: outpath,
                                    plaintext: "wow")
            }
        }
    }
}

