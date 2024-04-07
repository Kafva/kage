import SwiftUI
import OSLog

struct PwNodeView: View {
    @Environment(\.dismiss) var dismiss;
    @EnvironmentObject var appState: AppState

    @Binding var targetNode: PwNode?
    let forFolder: Bool

    @State private var selectedFolder = G.rootNodeName
    @State private var selectedName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var generate = true

    /// Return the PwNode object that is about to be inserted into the tree
    /// if valid values have been configured
    private var newPwNode: PwNode? {
        if selectedFolder.isEmpty ||
           selectedName.isEmpty ||
           !selectedFolder.isPrintableASCII ||
           !selectedName.isPrintableASCII {
            return nil
        }

        let parentURL = G.gitDir.appending(path: selectedFolder)

        // Parent must exist
        if !FileManager.default.isDir(parentURL) {
            return nil
        }

        let url = parentURL.appending(path: selectedName + (forFolder ? "" : ".age"))

        return PwNode(url: url, children: [])
    }

    private var newPwNodeIsValid: Bool {
       guard let newPwNode else {
           return false
       }
       return !FileManager.default.isFile(newPwNode.url) &&
              !FileManager.default.isDir(newPwNode.url)
    }

    private var newPasswordIsValid: Bool {
        if !newPwNodeIsValid {
            return false
        }
        if generate {
            return true
        }
        return !password.isEmpty && password == confirmPassword
    }

    var body: some View {
        let title: String
        let confirmAction: () -> ()
        let confirmIsOk: Bool

        if let targetNode {
            title = "Edit \(targetNode.name)"
            confirmAction = addPassword
            confirmIsOk = newPasswordIsValid

        } else if forFolder {
            title = "New folder"
            confirmAction = addFolder
            confirmIsOk = newPwNodeIsValid

        } else {
            title = "New password"
            confirmAction = addPassword
            confirmIsOk = newPasswordIsValid
        }

        return Form {
            Section(header: Text(title).font(.system(size: 20)).bold()) {
                VStack(alignment: .leading, spacing: 10) {
                    if let targetNode {
                        /* Edit password */
                        Text(targetNode.name)
                    } else {
                        /* New password or folder */
                        Picker(forFolder ? "Parent" : "Folder", selection: $selectedFolder) {
                            ForEach(appState.rootNode.flatFolders()) { node in
                                Text(node.relativePath).tag(node.relativePath)
                            }
                        }
                        .pickerStyle(.menu)

                        TextField("Name", text: $selectedName)
                            .textFieldStyle(.roundedBorder)
                            // TODO: color is not updated
                            // https://forums.developer.apple.com/forums/thread/738755
                            .foregroundColor(newPwNodeIsValid ? G.textColor : G.textColor)

                        if !forFolder {
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
                        }
                    }
                }
            }

            Section {
                Button(action: confirmAction) {
                    Text("Save").bold().font(.system(size: 18))
                }
                .padding([.top, .bottom], 20)
                .disabled(!confirmIsOk)
            }
        }
        .formStyle(.grouped)
    }

    private func addFolder() {
        guard let newPwNode else {
            return
        }
        do {
            try FileManager.default.createDirectory(at: newPwNode.url,
                                                    withIntermediateDirectories: false)

            try appState.reloadGitTree()
            dismiss()

        } catch {
            G.logger.error("\(error)")
        }
    }

    private func addPassword() {
        if !newPasswordIsValid {
            return
        }
        guard let newPwNode else {
            return
        }
        do {
            let recipient = G.gitDir.appending(path: ".age-recipients")

            try Age.encrypt(recipient: recipient,
                            outpath: newPwNode.url,
                            plaintext: password)

            try Git.addCommit(node: newPwNode)

            // Reload git tree with new entry
            try appState.reloadGitTree()
            dismiss()

        } catch {
            G.logger.error("\(error)")
            try? Git.reset()
        }
    }
}


