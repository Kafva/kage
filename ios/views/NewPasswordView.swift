import SwiftUI
import OSLog

struct NewPasswordView: View {
    @EnvironmentObject var appState: AppState

    @Binding var targetNode: PwNode?

    @State private var path = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var generate = true


    private var completion: String {
        if path.isEmpty {
            return " " // "Use '/' for folder paths"
        }

        let matches = appState.rootNode.findChildren(predicate: path, 
                                                     onlyFolders: true)
        let result = matches.map { $0.name }.joined(separator: ", ")

        if result.isEmpty {
            return " "
        }

        return result
    }

    private var validPasswordPath: Bool {
        return path.isPrintableASCII
    }

    private var validPassword: Bool {
        if generate {
            return true
        }
        return !password.isEmpty &&
               path.isPrintableASCII &&
               password == confirmPassword
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New password").font(.system(size: 20)).bold()
            Text(completion).foregroundColor(.gray)
            TextField("New password path", text: $path).textFieldStyle(.roundedBorder)

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

            VStack(alignment: .center) {
                Button(action: addPassword) {
                    Image(systemName: "key.viewfinder").bold().font(.system(size: 34))
                }
                .padding([.top, .bottom], 20)
                .disabled(!validPasswordPath || !validPassword)
            }
        }
        .frame(width: 0.8 * G.screenWidth)
    }

    private func addPassword() {
        if !validPasswordPath || !validPassword {
            return
        }

        do {
            let recipient = G.gitDir.appending(path: ".age-recipients")
            let outpath = G.gitDir.appending(path: path)

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


