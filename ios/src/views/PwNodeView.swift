import OSLog
import SwiftUI

struct PwNodeView: View {
    @EnvironmentObject var appState: AppState

    @Binding var showView: Bool
    @Binding var targetNode: PwNode?

    @State private var nodeType: PwNodeType = .folder
    @State private var selectedFolder = G.rootNodeName
    @State private var selectedName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var generate = true

    private var newPasswordIsValid: Bool {
        if generate {
            return true
        }
        return !password.isEmpty && password == confirmPassword
    }

    private var nodePathUnchanged: Bool {
        return targetNode?.parentName == selectedFolder
            && targetNode?.name == selectedName
    }

    private var passwordForm: some View {
        let underlineColor =
            password == confirmPassword ? Color.green : Color.red
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

    private var alternativeParentFolders: [PwNode] {
        if let targetNode {
            // We cannot move a folder to a path beneath itself,
            // exclude items beneath the current folder
            return appState.rootNode.flatFolders().filter {
                !$0.relativePath.starts(with: targetNode.relativePath)
            }
        }
        return appState.rootNode.flatFolders()
    }

    var body: some View {
        let title: String
        let confirmIsOk: Bool
        let newPwNode = PwNode.loadNewFrom(
            name: selectedName,
            relativeFolderPath: selectedFolder,
            isDir: nodeType == .folder)

        if let targetNode {
            if nodeType == .folder {
                title = "Edit folder '\(targetNode.name)'"
                confirmIsOk = newPwNode != nil
            }
            else {
                title = "Edit password '\(targetNode.name)'"
                // OK to keep the same name or password (empty)
                // when editing a password node
                confirmIsOk =
                    (newPwNode != nil || nodePathUnchanged)
                    && (password.isEmpty || password == confirmPassword)
            }
        }
        else if nodeType == .folder {
            title = ""
            confirmIsOk = newPwNode != nil
        }
        else {
            title = ""
            confirmIsOk = newPwNode != nil && newPasswordIsValid
        }

        let formHeight =
            (generate || nodeType == .folder)
            ? 0.25 * G.screenHeight : 0.4 * G.screenHeight
        let header = Text(title).font(G.title3Font)
            .padding(.bottom, 10)
            .textCase(nil)

        return VStack {
            if targetNode == nil {
                Picker("", selection: $nodeType) {
                    ForEach(PwNodeType.allCases) { p in
                        Text(p.rawValue.capitalized)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 0.8 * G.screenWidth)
                .padding([.top, .bottom], 20)
            }

            Form {
                Section(header: header) {
                    VStack(alignment: .leading, spacing: 10) {
                        /* New password or folder */
                        TileView(iconName: "folder") {
                            Picker("", selection: $selectedFolder) {
                                ForEach(alternativeParentFolders) { node in
                                    Text(node.relativePath).tag(
                                        node.relativePath)
                                }
                            }
                            .pickerStyle(.navigationLink)
                        }

                        TileView(
                            iconName: nodeType == .folder ? "folder" : "key"
                        ) {
                            TextField("Name", text: $selectedName)
                                .textFieldStyle(.roundedBorder)
                        }

                        if nodeType == .password {
                            if targetNode == nil {
                                TileView(iconName: "dice") {
                                    HStack {
                                        Text("Autogenerate").font(
                                            .system(size: 14)
                                        )
                                        .foregroundColor(.gray)
                                        Toggle(isOn: $generate) {}
                                    }
                                    .frame(alignment: .leading)
                                }
                            }
                            if targetNode != nil || !generate {
                                passwordForm
                            }
                        }
                    }
                }
            }
            .frame(width: G.screenWidth, height: formHeight)
            // .border(.red, width: 1)
            .formStyle(.grouped)

            // Both buttons are triggered when one is pressed if they are placed
            // inside the form...
            // https://www.hackingwithswift.com/forums/swiftui/buttons-in-a-form-section/6175
            HStack {
                Button(action: dismiss) {
                    Text("Cancel").foregroundColor(G.errorColor)
                        .font(G.bodyFont)
                }
                .padding(.leading, 30)

                Spacer()

                Button(action: { handleSubmit(newPwNode: newPwNode) }) {
                    Text("Save").font(G.bodyFont)
                }
                .disabled(!confirmIsOk)
                .padding(.trailing, 30)
            }
            .buttonStyle(BorderlessButtonStyle())

            Spacer()
        }
        .onAppear {
            // .on Appear is triggered anew when we navigate back from the
            // folder selection
            if let targetNode {
                G.logger.debug("Selected: '\(targetNode.relativePath)'")
                if selectedName.isEmpty {
                    selectedName = targetNode.name
                }
                if selectedFolder.isEmpty {
                    selectedFolder = targetNode.parentRelativePath
                }
            }
            else {
                G.logger.debug("No target node selected")
            }
        }

    }

    private func handleSubmit(newPwNode: PwNode?) {
        // The new PwNode must always be valid except for when we are changing
        // the password value of an existing node.
        if let targetNode, nodeType == .password {
            changePasswordNode(
                currentPwNode: targetNode,
                newPwNode: newPwNode)
            return
        }

        guard let newPwNode else {
            appState.uiError(
                "Invalid path selected: '\(selectedFolder)/\(selectedName)'")
            return
        }

        if let targetNode, nodeType == .folder {
            renameFolder(
                currentPwNode: targetNode,
                newPwNode: newPwNode)
            return
        }

        if nodeType == .folder {
            addFolder(newPwNode: newPwNode)
        }
        else {
            addPassword(newPwNode: newPwNode)
        }
    }

    private func dismiss() {
        G.logger.debug("Dismissing overlay")
        withAnimation {
            showView = false
            self.targetNode = nil
        }
    }

    private func addFolder(newPwNode: PwNode) {
        do {
            try FileManager.default.createDirectory(
                at: newPwNode.url,
                withIntermediateDirectories: false)

            try appState.reloadGitTree()
            dismiss()

        }
        catch {
            appState.uiError("\(error.localizedDescription)")
            try? FileManager.default.removeItem(at: newPwNode.url)
        }
    }

    private func renameFolder(
        currentPwNode: PwNode,
        newPwNode: PwNode
    ) {
        do {
            try Git.mvCommit(fromNode: currentPwNode, toNode: newPwNode)

            try appState.reloadGitTree()
            dismiss()

        }
        catch {
            appState.uiError("\(error.localizedDescription)")
            try? FileManager.default.removeItem(at: newPwNode.url)
            try? Git.reset()
        }
    }

    /// Separate commits are created for moving a password and changing its value
    private func changePasswordNode(
        currentPwNode: PwNode,
        newPwNode: PwNode?
    ) {
        // Select the new node if it will be moved, otherwise use the selected node
        let pwNode = newPwNode ?? currentPwNode
        do {
            // Move the password node if the current and new node are different
            if let newPwNode, currentPwNode.url != newPwNode.url {
                try Git.mvCommit(fromNode: currentPwNode, toNode: newPwNode)
            }

            // Change the password value
            if !password.isEmpty && password == confirmPassword {
                let recipient = G.gitDir.appending(path: ".age-recipients")

                try Age.encrypt(
                    recipient: recipient,
                    outpath: pwNode.url,
                    plaintext: password)

                try Git.addCommit(node: pwNode, nodeIsNew: !nodePathUnchanged)
            }

            try appState.reloadGitTree()
            dismiss()

        }
        catch {
            appState.uiError("\(error.localizedDescription)")
            if let newPwNode {
                try? FileManager.default.removeItem(at: newPwNode.url)
            }
            try? Git.reset()
        }
    }

    private func addPassword(newPwNode: PwNode) {
        if !newPasswordIsValid {
            appState.uiError("passwords do not match")
            return
        }
        do {
            let recipient = G.gitDir.appending(path: ".age-recipients")
            let plaintext = generate ? String.random(18) : password

            try Age.encrypt(
                recipient: recipient,
                outpath: newPwNode.url,
                plaintext: plaintext)

            try Git.addCommit(node: newPwNode, nodeIsNew: true)

            // Reload git tree with new entry
            try appState.reloadGitTree()
            dismiss()

        }
        catch {
            appState.uiError("\(error.localizedDescription)")
            try? Git.reset()
        }
    }
}
