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
            return "Use '/' for folder paths"
        }

        let matches = appState.rootNode.findChildren(predicate: path, 
                                                     onlyFolders: true)
        let result = matches.map { $0.name }.joined(separator: ", ")

        if path.contains("/") && result.isEmpty {
            return "[New folder(s)]"
        }
        else if result.isEmpty {
            return " "
        }

        return result
    }


    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            Text("Add a new password").font(.headline).padding(.bottom, 20)
                                    

            Text(completion).foregroundColor(.gray)
            TextField("Password path", text: $path).textFieldStyle(.roundedBorder)

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

            Button {
                if password == confirmPassword {
                    addPassword(password: password)
                } else {
                    G.logger.debug("Passwords do not match")
                }
            } label: {
                Image(systemName: "key.viewfinder").bold()
            }.controlSize(.large)
        }
        
        .frame(width: 0.8 * G.screenWidth)
    }

    private func addPassword(password: String) {
        let recipient = G.gitDir.appending(path: ".age-recipients")
        let outpath = G.gitDir.appending(path: "iOS.age")
        let r = Age.encrypt(recipient: recipient,
                            outpath: outpath,
                            plaintext: password)
        if r {
            appState.loadGitTree()
        }
    }
}


