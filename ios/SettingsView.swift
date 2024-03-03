import SwiftUI
import OSLog


struct SettingsView: View {
    @AppStorage("remote") private var remote: String = ""
    let gitDir = FileManager.default.gitDirectory
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("Clone").onTapGesture {
                // TODO progress view
                try? FileManager.default.removeItem(at: gitDir)
                Git.clone(remote: remote, into: gitDir);
            }

            Text("Pull").onTapGesture {
                Git.pull(gitDir);
            }

            Text("Encrypt").onTapGesture {
                let recipient = gitDir.appending(path: ".age-recipients")
                let outpath = gitDir.appending(path: "iOS.age")
                let _ = Age.encrypt(recipient: recipient,
                                    outpath: outpath,
                                    plaintext: "wow")
            }
        }
    }
}

