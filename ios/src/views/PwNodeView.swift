import OSLog
import SwiftUI

struct PwNodeView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    var node: PwNode?

    @State private var nodeType: PwNodeType = .password
    @State private var selectedFolder = ""
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

    private var directorySelected: Bool {
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

        let formHeader = Text(title).font(G.title3Font)
            .padding(.bottom, 10)
            .padding(.top, 20)
            .textCase(nil)

        return Form {
            Section(header: formHeader) {
                if node == nil {
                    nodeTypePickerView.listRowSeparator(.hidden)
                }
                directorySelectionView
                nameSelectionView.listRowSeparator(.automatic)

                if !directorySelected {
                    passwordSelectionView
                }

                if currentError != nil {
                    ErrorTileView(currentError: $currentError)
                }

                HStack {
                    Button("Cancel") {
                        handleDismiss()
                    }
                    .buttonStyle(.bordered)
                    .tint(G.errorColor)
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
    }

    private var nameSelectionView: some View {
        TileView(iconName: directorySelected ? "folder" : "key") {
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
                TileView(iconName: "rectangle.and.pencil.and.ellipsis") {
                    ZStack(alignment: .trailing) {
                        Group {
                            if showPassword {
                                TextField("Password", text: $password)
                            }
                            else {
                                SecureField("Password", text: $password)
                            }
                        }
                        // Prevent the hitbox of the textfield and button from overlapping
                        .padding(.trailing, 32)
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(
                                systemName: showPassword ? "eye.slash" : "eye"
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
            // The `newPwNode` and `node` are equal if we are modifying an existing node
            newPwNode = try PwNode.loadValidatedFrom(
                name: selectedName, relativePath: selectedFolder,
                expectPassword: !directorySelected, checkParents: true,
                allowNameTaken: false)

            try PwManager.submit(
                currentPwNode: node,
                newPwNode: newPwNode!,
                directorySelected: directorySelected,
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
            if selectedFolder.isEmpty {
                selectedFolder = G.rootNodeName
            }
            return
        }

        G.logger.debug("Current node: '\(node.relativePath)'")
        if selectedName.isEmpty {
            selectedName = node.name
        }
        if selectedFolder.isEmpty {
            selectedFolder = node.parentRelativePath
        }
        G.logger.debug("Selected: '\(selectedFolder)/\(selectedName)'")
    }

    private func handleDismiss() {
        hideKeyboard()
        dismiss()
    }
}
