import SwiftUI

struct PwNodeView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    var node: PwNode?

    @State private var nodeType: PwNodeType = .password
    @State private var selectedRelativePath = ""
    @State private var selectedName = ""
    @State private var password = ""
    @State private var showPassword: Bool = false
    @State private var generate = true
    @State private var currentError: String?

    private var alternativeParentFolders: [PwNode] {
        if let node {
            // We cannot move a folder to a path beneath itself,
            // exclude items beneath the current folder
            return appState.rootNode.flatFolders().filter {
                !$0.relativePath.starts(with: node.relativePath)
            }
        }
        return appState.rootNode.flatFolders()
    }

    private var selectedDirectory: Bool {
        if let node {
            return !node.isPassword
        }
        return nodeType == .folder
    }

    var body: some View {
        let title: String
        let passwordIsOk: Bool

        if let node {
            if node.isPassword {
                title = "Edit password '\(node.name)'"
                passwordIsOk = generate || !password.isEmpty
            }
            else {
                title = "Edit folder '\(node.name)'"
                passwordIsOk = true
            }
        }
        // No node currently selected
        else if nodeType == .folder {
            title = "New item"
            passwordIsOk = true
        }
        else {
            title = "New item"
            passwordIsOk = generate || !password.isEmpty
        }

        return Form {
            Section(header: Text(title).formHeaderStyle()) {
                if node == nil {
                    nodeTypePickerView.listRowSeparator(.hidden)
                }
                directorySelectionView
                nameSelectionView.listRowSeparator(.automatic)

                if !selectedDirectory {
                    passwordSelectionView
                }

                if currentError != nil {
                    ErrorTileView(currentError: $currentError).listRowSeparator(
                        .hidden)
                }

                HStack {
                    Button("Dismiss") {
                        handleDismiss()
                    }
                    .buttonStyle(.bordered)
                    .padding(.leading, 5)

                    Spacer()

                    Button("Save") {
                        handleSubmit()
                    }
                    .buttonStyle(.bordered)
                    .tint(.accentColor)
                    .disabled(!passwordIsOk)
                    .padding(.trailing, 5)
                }
                .padding(.top, 40)
            }
        }
        .formStyle(.grouped)
        .navigationBarHidden(true)
        .onAppear {
            handleOnAppear()
        }
    }

    private var nodeTypePickerView: some View {
        Picker("", selection: $nodeType) {
            ForEach(PwNodeType.allCases) { p in
                Text(p.rawValue.capitalized)
            }
        }
        .pickerStyle(.segmented)
        .padding(.top, 8)
        .padding(.bottom, 5)
    }

    private var directorySelectionView: some View {
        TileView(iconName: "folder") {
            Picker("", selection: $selectedRelativePath) {
                ForEach(
                    alternativeParentFolders.sorted {
                        a, b
                        in a.relativePath < b.relativePath
                    }
                ) { node in
                    Text(node.relativePath).lineLimit(1).tag(
                        node.relativePath)
                }
            }
            .pickerStyle(.navigationLink)
        }
    }

    private var nameSelectionView: some View {
        TileView(iconName: selectedDirectory ? "folder" : "key") {
            TextField("Name", text: $selectedName)
                .textContentType(.oneTimeCode)
                .padding(.bottom, 5)
        }
    }

    private var passwordSelectionView: some View {
        Group {
            if node == nil {
                TileView(iconName: "dice") {
                    HStack {
                        Text("Autogenerate").font(G.bodyFont)
                            .foregroundColor(.gray)

                        Toggle(isOn: $generate) {}
                    }
                    .frame(alignment: .leading)
                }
                .listRowSeparator(.hidden)
            }
            if node != nil || !generate {
                let placeholder = node != nil ? "New password" : "Password"
                TileView(iconName: "rectangle.and.pencil.and.ellipsis") {
                    ZStack(alignment: .trailing) {
                        Group {
                            if showPassword {
                                TextField(placeholder, text: $password)
                            }
                            else {
                                SecureField(placeholder, text: $password)
                            }
                        }
                        .textContentType(.oneTimeCode)
                        // Prevent the hitbox of the textfield and button from overlapping
                        .padding(.trailing, 32)
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(
                                systemName: showPassword
                                    ? "eye.fill" : "eye.slash.fill"
                            )
                            .accentColor(.gray)
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
        }
    }

    private func handleSubmit() {
        var newPwNode: PwNode? = nil
        do {
            newPwNode = try PwManager.submit(
                selectedName: selectedName,
                selectedRelativePath: selectedRelativePath,
                selectedDirectory: selectedDirectory,
                currentPwNode: node,
                password: password,
                generate: generate)

            // Reload git tree with new entry
            try appState.reloadGitTree()
            handleDismiss()
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

    private func handleOnAppear() {
        // .on Appear is triggered anew when we navigate back from the
        // folder selection
        guard let node else {
            if selectedRelativePath.isEmpty {
                selectedRelativePath = G.rootNodeName
            }
            return
        }

        G.logger.debug("Current node: '\(node.relativePath)'")
        if selectedName.isEmpty {
            selectedName = node.name
        }
        if selectedRelativePath.isEmpty {
            selectedRelativePath = node.parentRelativePath
        }
        G.logger.debug(
            "Selected: ['\(selectedRelativePath)', '\(selectedName)']")
    }

    private func handleDismiss() {
        hideKeyboard()
        dismiss()
    }
}
