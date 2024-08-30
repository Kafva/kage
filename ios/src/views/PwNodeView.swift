import OSLog
import SwiftUI

struct PwNodeView: View {
    @EnvironmentObject var appState: AppState

    @Binding var showView: Bool
    @Binding var currentPwNode: PwNode?

    @State private var nodeType: PwNodeType = .password
    @State private var selectedFolder = ""
    @State private var selectedName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var generate = true
    @State private var currentError: String?

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
        if let currentPwNode {
            // We cannot move a folder to a path beneath itself,
            // exclude items beneath the current folder
            return appState.rootNode.flatFolders().filter {
                !$0.relativePath.starts(with: currentPwNode.relativePath)
            }
        }
        return appState.rootNode.flatFolders()
    }

    private var directorySelected: Bool {
        if let currentPwNode {
            return !currentPwNode.isPassword
        }
        return nodeType == .folder
    }

    var body: some View {
        let title: String
        let passwordIsOk: Bool

        if let currentPwNode {
            if currentPwNode.isPassword {
                title = "Edit password '\(currentPwNode.name)'"
                passwordIsOk = (password.isEmpty || password == confirmPassword)
            }
            else {
                title = "Edit folder '\(currentPwNode.name)'"
                passwordIsOk = true
            }
        }
        // No node currently selected
        else if nodeType == .folder {
            title = ""
            passwordIsOk = true
        }
        else {
            title = ""
            passwordIsOk =
                (generate || (!password.isEmpty && password == confirmPassword))
        }

        let header = Text(title).font(G.title3Font)
            .padding(.bottom, 10)
            .textCase(nil)

        return VStack {
            if currentPwNode == nil {
                Picker("", selection: $nodeType) {
                    ForEach(PwNodeType.allCases) { p in
                        Text(p.rawValue.capitalized)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 0.8 * G.screenWidth)
                .padding(.bottom, 5)
            }

            Form {
                Section(header: header) {
                    VStack(alignment: .leading, spacing: 10) {
                        /* New password or folder */
                        TileView(iconName: "folder") {
                            Picker("", selection: $selectedFolder) {
                                ForEach(
                                    alternativeParentFolders.sorted {
                                        a, b
                                        in a.relativePath < b.relativePath
                                    }
                                ) { node in
                                    Text(node.relativePath).tag(
                                        node.relativePath)
                                }
                            }
                            .pickerStyle(.navigationLink)
                        }

                        TileView(iconName: directorySelected ? "folder" : "key")
                        {
                            TextField("Name", text: $selectedName)
                                .textContentType(.oneTimeCode)
                                .textFieldStyle(.roundedBorder)

                        }

                        if !directorySelected {
                            if currentPwNode == nil {
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
                            if currentPwNode != nil || !generate {
                                passwordForm
                            }
                        }

                        if currentError != nil {
                            ErrorTileView(currentError: $currentError)
                        }
                    }
                }
            }
            .frame(width: G.screenWidth, height: 0.4 * G.screenHeight)
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

                Button(action: { handleSubmit() }) {
                    Text("Save").font(G.bodyFont)
                }
                .disabled(!passwordIsOk)
                .padding(.trailing, 30)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            // .on Appear is triggered anew when we navigate back from the
            // folder selection
            guard let currentPwNode else {
                if selectedFolder.isEmpty {
                    selectedFolder = G.rootNodeName
                }
                return
            }

            G.logger.debug("Current node: '\(currentPwNode.relativePath)'")
            if selectedName.isEmpty {
                selectedName = currentPwNode.name
            }
            if selectedFolder.isEmpty {
                selectedFolder = currentPwNode.parentRelativePath
            }
            G.logger.debug("Selected: '\(selectedFolder)/\(selectedName)'")
        }
    }

    private func handleSubmit() {
        var newPwNode: PwNode? = nil
        do {
            // The `newPwNode` and `currentPwNode` are equal if we are modifying an existing node
            newPwNode = try PwNode.loadValidatedFrom(
                name: selectedName, relativePath: selectedFolder,
                expectPassword: !directorySelected, checkParents: true,
                allowNameTaken: false)

            try PwManager.submit(
                currentPwNode: currentPwNode,
                newPwNode: newPwNode!,
                directorySelected: directorySelected,
                password: password,
                confirmPassword: confirmPassword,
                generate: generate)

            // Reload git tree with new entry
            try appState.reloadGitTree()
            dismiss()
        }
        catch {
            currentError = uiError("\(error.localizedDescription)")

            do {
                try Git.reset()
            }
            catch {
                G.logger.error("\(error.localizedDescription)")
            }

            if let newPwNode {
                try? FileManager.default.removeItem(at: newPwNode.url)
            }
        }
    }

    private func dismiss() {
        G.logger.debug("Dismissing overlay")
        hideKeyboard()
        self.showView = false
        self.currentPwNode = nil
    }
}
