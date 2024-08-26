import OSLog
import SwiftUI

struct TreeView: View {
    @EnvironmentObject var appState: AppState

    @Binding var searchText: String
    @Binding var currentPwNode: PwNode?
    @Binding var showPwNode: Bool
    @Binding var showPlaintext: Bool
    @Binding var expandTree: Bool

    var body: some View {
        List {
            ForEach(searchResults, id: \.id) { child in
                let parentMatchesSearch = child.name
                    .localizedCaseInsensitiveContains(searchText)
                TreeNodeView(
                    node: child,
                    parentMatchesSearch: parentMatchesSearch,
                    searchText: $searchText,
                    currentPwNode: $currentPwNode,
                    showPwNode: $showPwNode,
                    showPlaintext: $showPlaintext,
                    expandTree: $expandTree)
            }
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
    @Binding var currentPwNode: PwNode?
    @Binding var showPwNode: Bool
    @Binding var showPlaintext: Bool
    @Binding var expandTree: Bool

    @State private var isExpanded: Bool = false

    var body: some View {
        if node.isPassword {
            if searchText.isEmpty || parentMatchesSearch
                || node.name.localizedCaseInsensitiveContains(searchText)
            {
                PwNodeTreeItemView(
                    node: node,
                    currentPwNode: $currentPwNode,
                    showPwNode: $showPwNode,
                    showPlaintext: $showPlaintext)

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
                        currentPwNode: $currentPwNode,
                        showPwNode: $showPwNode,
                        showPlaintext: $showPlaintext,
                        expandTree: $expandTree)

                }
            } label: {
                PwNodeTreeItemView(
                    node: node,
                    currentPwNode: $currentPwNode,
                    showPwNode: $showPwNode,
                    showPlaintext: $showPlaintext)

            }
        }
    }
}

private struct PwNodeTreeItemView: View {
    @EnvironmentObject var appState: AppState

    let node: PwNode
    @Binding var currentPwNode: PwNode?
    @Binding var showPwNode: Bool
    @Binding var showPlaintext: Bool

    var body: some View {
        Group {
            if node.isPassword {
                HStack {
                    Text(node.name)
                    Spacer()
                }
                // XXX: A contentShape() is  needed for the Spacer() to take
                // effect and make the hitbox take up the entire row.
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                    G.logger.debug("Opening '\(node.name)'")

                    if !node.isPassword {
                        return
                    }
                    currentPwNode = node
                    showPlaintext = true
                }
            }
            else {
                Text(node.name)
            }
        }
        .font(G.bodyFont)
        .swipeActions(allowsFullSwipe: false) {
            Button(action: {
                hideKeyboard()
                handleRemove(node: node)
            }) {
                Image(systemName: "xmark.circle")
            }
            .tint(.red)

            Button(action: {
                hideKeyboard()
                currentPwNode = node
                showPwNode = true
            }) {
                Image(systemName: "pencil")
            }
            .tint(.blue)
        }
    }

    private func handleRemove(node: PwNode) {
        do {
            try PwManager.remove(node: node)
            try appState.reloadGitTree()

        }
        catch {
            appState.uiError("\(error.localizedDescription)")
            do {
                try Git.reset()
            }
            catch {
                G.logger.error("\(error.localizedDescription)")
            }
        }
    }
}
