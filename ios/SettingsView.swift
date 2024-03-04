import SwiftUI
import OSLog


struct SettingsView: View {
    @AppStorage("remote") private var remote: String = ""

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("Clone").onTapGesture {
                // TODO progress view
                try? FileManager.default.removeItem(at: GIT_DIR)
                Git.clone(remote: remote, into: GIT_DIR);
            }

            Text("Pull").onTapGesture {
                Git.pull(GIT_DIR);
            }

            Text("Encrypt").onTapGesture {
                let recipient = GIT_DIR.appending(path: ".age-recipients")
                let outpath = GIT_DIR.appending(path: "iOS.age")
                let _ = Age.encrypt(recipient: recipient,
                                    outpath: outpath,
                                    plaintext: "wow")
            }
        }
    }
}

