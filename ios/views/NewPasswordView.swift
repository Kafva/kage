import SwiftUI
import OSLog

struct NewPasswordView: View {
    @EnvironmentObject var appState: AppState

    @State private var selectedFolder = G.rootNodeName
    @State private var selectedName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var generate = true

    private var validPasswordPath: Bool {
        return selectedFolder.isPrintableASCII
    }

    private var validPassword: Bool {
        if generate {
            return true
        }
        return !password.isEmpty &&
               selectedFolder.isPrintableASCII &&
               password == confirmPassword
    }

    private var formBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Folder", selection: $selectedFolder) {
                ForEach(appState.rootNode.flatFolders()) { node in
                    Text(node.path).tag(node.path)
                }
            }
            .pickerStyle(.menu)

            TextField("Name", text: $selectedName).textFieldStyle(.roundedBorder)

            Toggle(isOn: $generate) {
                Text("Autogenerate")
            }

            if !generate {
                let underlineColor = !password.isEmpty && password == confirmPassword ?
                                      Color.green : Color.red
                SecureField("Password", text: $password).textFieldStyle(.plain)
                SecureField("Confirm password", text: $confirmPassword).textFieldStyle(.plain)
                Divider().frame(height: 2)
                         .overlay(underlineColor)
            }

            Button(action: addPassword) {
                Text("Confirm").bold().font(.system(size: 18))
            }
            .padding([.top, .bottom], 20)
            .disabled(!validPasswordPath || !validPassword)
        }
    }

    var body: some View {
        Form {
            Section(header: Text("New password").font(.system(size: 20)).bold()) {
                formBody
            }
        }
        .formStyle(.grouped)
    }

    private func addPassword() {
        if !validPasswordPath || !validPassword {
            return
        }

        do {
            let recipient = G.gitDir.appending(path: ".age-recipients")
            let outpath = G.gitDir.appending(path: selectedName)

            try FileManager.default.mkdirp(outpath.deletingLastPathComponent())

            try Age.encrypt(recipient: recipient,
                            outpath: outpath,
                            plaintext: password)

            // TODO git add .
            // TODO git commit -m ""

            // Reload git tree with new entry
            try appState.reloadGitTree()

        } catch {
            G.logger.error("\(error)")
        }
    }
}


