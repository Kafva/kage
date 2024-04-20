import SwiftUI
import OSLog

struct PwNodeView: View {
    @EnvironmentObject var appState: AppState

    @Binding var showView: Bool
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
            confirmAction = forFolder ? renameFolder : changeNode

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
            let header = Text(title).font(G.headerFont)
                                    .padding(.bottom, 10)
                                    .textCase(nil)

            Section(header: header) {
                VStack(alignment: .leading, spacing: 10) {
                    /* New password or folder */
                    TileView(iconName: "folder") {
                        Picker("", selection: $selectedFolder) {
                            ForEach(appState.rootNode.flatFolders()) { node in
                                Text(node.relativePath).tag(node.relativePath)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }

                    TileView(iconName: "key") {
                        TextField("Name", text: $selectedName)
                            .textFieldStyle(.roundedBorder)
                    }

                    if !forFolder {
                        if targetNode == nil {
                            TileView(iconName: "dice", text: "Autogenerate") {
                                Toggle(isOn: $generate) {}
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
                HStack {
                    Button(action: confirmAction) {
                        Text("Save").font(.system(size: 18))
                    }
                    .disabled(!confirmIsOk)
                    Spacer()

                    Button(action: dismiss) {
                        Text("Cancel").foregroundColor(G.errorColor).font(.system(size: 18))
                    }
                }
                .padding([.top, .bottom], 5)
            }
        }
        .formStyle(.grouped)
    }

    private func dismiss() {
        withAnimation { 
            showView = false
            self.targetNode = nil
        }
    }

    private var passwordForm: some View {
        let underlineColor = password == confirmPassword ? Color.green : 
                                                           Color.red
        return Group {
            TileView(iconName: "rectangle.and.pencil.and.ellipsis") {
                SecureField("Password", text: $password)
            }
            .padding(.bottom, 10)
            TileView(iconName: nil) {
                SecureField("Confirm", text: $confirmPassword)
            }

            Divider().frame(height: 2)
                     .overlay(underlineColor)
                     .opacity(password.isEmpty ? 0.0 : 1.0)
        }
        .textFieldStyle(.roundedBorder)
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
            try? FileManager.default.removeItem(at: newPwNode.url)
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
            try? FileManager.default.removeItem(at: newPwNode.url)
            try? Git.reset()
        }
    }

    /// Seperate commits are created for moving a password and changing its value
    private func changeNode() {
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
            try? FileManager.default.removeItem(at: newPwNode.url)
            try? Git.reset()
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


struct TileView<Content: View>: View {
    let iconName: String?
    var text: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        let width = text != nil ? G.screenWidth*0.15 : G.screenWidth*0.1
        return HStack {
            Group {
                Image(systemName: iconName ?? "globe").opacity(iconName != nil ? 1.0 : 0.0)
                if let text {
                    Text(text).font(.system(size: 14)).foregroundColor(.gray)
                }
            }
            .frame(width: width, alignment: .leading)
            content
        }
    }
}
