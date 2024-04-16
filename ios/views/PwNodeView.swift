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

    private var newPwNode: PwNode? {
       return PwNode.loadNewFrom(name: selectedName,
                                 relativeFolderPath: selectedFolder,
                                 isDir: forFolder)
    }

    private var newPasswordIsValid: Bool {
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
            confirmAction = forFolder ? renameFolder : changePassword

            if forFolder {
                confirmIsOk = newPwNode != nil
            } else {
                confirmIsOk = newPwNode != nil && (password.isEmpty ||
                                                   password == confirmPassword)
            }

        } else if forFolder {
            title = "New folder"
            confirmAction = addFolder
            confirmIsOk = newPwNode != nil

        } else {
            title = "New password"
            confirmAction = addPassword
            confirmIsOk = newPwNode != nil && newPasswordIsValid
        }

        return Form {
            let header = Text(title).font(.system(size: 20))
                                    .bold()
                                    .padding(.bottom, 10)
                                    .padding(.top, 20)

            Section(header: header) {
                VStack(alignment: .leading, spacing: 10) {
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
                        // .foregroundColor(newPwNode != nil ? G.textColor : Color.red)

                    if !forFolder {
                        if targetNode == nil {
                            Toggle(isOn: $generate) {
                                Text("Autogenerate")
                            }
                        }
                        if targetNode != nil || !generate {
                            passwordForm
                        }
                    }
                }
                .onAppear {
                    if let targetNode {
                        selectedName = targetNode.name
                        selectedFolder = targetNode.parentRelativePath
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

    private var passwordForm: some View {
        let underlineColor = !password.isEmpty && password == confirmPassword ?
                              Color.green : Color.red
        return Group {
            SecureField("Password", text: $password).textFieldStyle(.plain)
            SecureField("Confirm password", text: $confirmPassword).textFieldStyle(.plain)
            Divider().frame(height: 2)
                     .overlay(underlineColor)
        }
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

    private func renameFolder() {
        guard let newPwNode, let targetNode else {
            return
        }
        do {
            try Git.mvCommit(fromNode: targetNode, toNode: newPwNode)

            try appState.reloadGitTree()
            dismiss()

        } catch {
            G.logger.error("\(error)")
        }
    }

    /// Seperate commits are created for moving a password and changing its value
    private func changePassword() {
        guard let newPwNode, let targetNode else {
            return
        }
        do {
            // Move the password node
            if targetNode.url != newPwNode.url {
                try Git.mvCommit(fromNode: targetNode, toNode: newPwNode)
            }

            // Change the password value
            if !password.isEmpty && password == confirmPassword {
                let recipient = G.gitDir.appending(path: ".age-recipients")

                try Age.encrypt(recipient: recipient,
                                outpath: newPwNode.url,
                                plaintext: password)

                try Git.addCommit(node: newPwNode, nodeIsNew: false)
            }

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

            try Git.addCommit(node: newPwNode, nodeIsNew: true)

            // Reload git tree with new entry
            try appState.reloadGitTree()
            dismiss()

        } catch {
            G.logger.error("\(error)")
            try? Git.reset()
        }
    }
}


