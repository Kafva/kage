import SwiftUI
import OSLog

struct NewPasswordView: View {
    @EnvironmentObject var appState: AppState

    @State private var selectedFolder = G.rootNodeName
    @State private var selectedName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var generate = true

    private var passwordURL: URL? {
        if selectedFolder.isEmpty ||
           selectedName.isEmpty ||
           !selectedFolder.isPrintableASCII ||
           !selectedName.isPrintableASCII {
            return nil
        }
        return G.gitDir.appending(path: selectedFolder)
                       .appending(path: selectedName + ".age")
    }

    private var validPasswordURL: Bool {
       guard let passwordURL else {
           return false
       }
       return !FileManager.default.isFile(passwordURL)
    }

    private var validPassword: Bool {
        if generate {
            return true
        }
        return !password.isEmpty && password == confirmPassword
    }

    private var formBody: some View {
        return VStack(alignment: .leading, spacing: 10) {
            Picker("Folder", selection: $selectedFolder) {
                ForEach(appState.rootNode.flatFolders()) { node in
                    Text(node.path).tag(node.path)
                }
            }
            .pickerStyle(.menu)

            TextField("Name", text: $selectedName)
                .textFieldStyle(.roundedBorder)
                // TODO: https://forums.developer.apple.com/forums/thread/738755
                .foregroundColor(validPasswordURL ? G.textColor : G.textColor)

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
            .disabled(!validPasswordURL || !validPassword)
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
        if !validPassword {
            return
        }
        guard let outpath = passwordURL else {
            return
        }

        do {
            let recipient = G.gitDir.appending(path: ".age-recipients")

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


