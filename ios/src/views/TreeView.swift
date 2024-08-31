import SwiftUI

struct TreeView: View {
    @EnvironmentObject var appState: AppState

    @Binding var searchText: String
    @Binding var expandTree: Bool
    @Binding var currentError: String?

    var body: some View {
        List {
            ForEach(searchResults, id: \.id) { child in
                let parentMatchesSearch = child.name
                    .localizedCaseInsensitiveContains(searchText)
                TreeNodeView(
                    node: child,
                    parentMatchesSearch: parentMatchesSearch,
                    searchText: $searchText,
                    expandTree: $expandTree,
                    currentError: $currentError)
            }
        }
        // Handler for NavigationLink(value:), this is used to hide the
        // the right-hand-side arrow that appears by default when using a
        // NavigationLink...
        .navigationDestination(for: PwNode.self) { node in
            PasswordView(node: node)
        }
        .listStyle(.plain)
        .frame(
            width: 0.9 * G.screenWidth,
            alignment: .top)
    }

    private var searchResults: [PwNode] {
        if searchText.isEmpty {
            return appState.rootNode.children ?? []
        }
        else {
            return appState.rootNode.findChildren(predicate: searchText)
        }
    }
}

private struct TreeNodeView: View {
    let node: PwNode
    let parentMatchesSearch: Bool

    @Binding var searchText: String
    @Binding var expandTree: Bool
    @Binding var currentError: String?

    @State private var isExpanded: Bool = false

    var body: some View {
        if node.isPassword {
            if searchText.isEmpty || parentMatchesSearch
                || node.name.localizedCaseInsensitiveContains(searchText)
            {
                PwNodeTreeItemView(node: node, currentError: $currentError)

            }
        }
        else {
            // Force all nodes into their expanded state when there is a search query
            // or the 'expand all' switch is active.
            let isExpanded =
                (!searchText.isEmpty || expandTree)
                ? Binding.constant(true) : $isExpanded
            DisclosureGroup(isExpanded: isExpanded) {
                ForEach(node.children ?? [], id: \.id) { child in
                    TreeNodeView(
                        node: child,
                        parentMatchesSearch: parentMatchesSearch,
                        searchText: $searchText,
                        expandTree: $expandTree,
                        currentError: $currentError)
                }
            } label: {
                PwNodeTreeItemView(node: node, currentError: $currentError)
            }
        }
    }
}

private struct PwNodeTreeItemView: View {
    @EnvironmentObject var appState: AppState

    let node: PwNode
    @Binding var currentError: String?
    @State private var showAlert: Bool = false

    var body: some View {
        ZStack(alignment: .leading) {
            if node.isPassword {
                NavigationLink(value: node) {
                    EmptyView()
                }
                // Hide navigation link arrow, this element is still present
                // so the dimensions of the Text() are limited.
                .opacity(0.0)
            }
            Text(node.name)
        }
        .font(G.bodyFont)
        .swipeActions(allowsFullSwipe: false) {
            Button(action: {
                hideKeyboard()
                showAlert = true
            }) {
                Image(systemName: "xmark.circle")
            }
            .tint(.red)

            NavigationLink(destination: PwNodeView(node: node)) {
                Image(systemName: "pencil").tint(.blue)
            }
        }
        .alert(
            "Delete \(node.name)?", isPresented: $showAlert
        ) {
            Button("Yes", role: .destructive) {
                handleRemove(node: node)
            }
            Button("Cancel", role: .cancel) {
                showAlert = false
            }
        }
    }

    private func handleRemove(node: PwNode) {
        do {
            try PwManager.remove(node: node)
            try appState.reloadGitTree()
            currentError = nil
        }
        catch {
            currentError = uiError("\(error.localizedDescription)")
            do {
                try Git.reset()
            }
            catch {
                G.logger.error("\(error.localizedDescription)")
            }
        }
    }
}
