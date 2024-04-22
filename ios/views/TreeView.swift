import SwiftUI
import OSLog

struct TreeView: View {
    @EnvironmentObject var appState: AppState

    @Binding var searchText: String
    @Binding var targetNode: PwNode?
    @Binding var showPwNode: Bool
    @Binding var showPlaintext: Bool
    @Binding var expandTree: Bool

    var body: some View {
        List {
            ForEach(searchResults, id: \.id) { child in
                let parentMatchesSearch = child.name.localizedCaseInsensitiveContains(searchText)
                TreeNodeView(node: child,
                             parentMatchesSearch: parentMatchesSearch,
                             searchText: $searchText,
                             targetNode: $targetNode,
                             showPwNode: $showPwNode, 
                             showPlaintext: $showPlaintext,
                             expandTree: $expandTree)
            }
        }
        .listStyle(.plain)
        .frame(width: 0.9*G.screenWidth,
               alignment: .top)
    }

    private var searchResults: [PwNode] {
        if searchText.isEmpty {
            return appState.rootNode.children ?? []
        } else {
            return appState.rootNode.findChildren(predicate: searchText)
        }
    }
}

private struct TreeNodeView: View {
    let node: PwNode
    let parentMatchesSearch: Bool

    @Binding var searchText: String
    @Binding var targetNode: PwNode?
    @Binding var showPwNode: Bool
    @Binding var showPlaintext: Bool
    @Binding var expandTree: Bool

    @State private var isExpanded: Bool = false

    var body: some View {
        if node.isLeaf {
            if searchText.isEmpty ||
               parentMatchesSearch ||
               node.name.localizedCaseInsensitiveContains(searchText) {
                PwNodeTreeItemView(node: node,
                                   targetNode: $targetNode,
                                   showPwNode: $showPwNode, 
                                   showPlaintext: $showPlaintext)

            }
        } else {
            // Force all nodes into their expanded state when there is a search query
            // or the 'expand all' switch is active.
            let isExpanded = (!searchText.isEmpty || expandTree) ? 
                                        Binding.constant(true) :
                                        $isExpanded
            DisclosureGroup(isExpanded: isExpanded) {
                ForEach(node.children ?? [], id: \.id) { child in
                    TreeNodeView(node: child,
                                 parentMatchesSearch: parentMatchesSearch,
                                 searchText: $searchText,
                                 targetNode: $targetNode,
                                 showPwNode: $showPwNode, 
                                 showPlaintext: $showPlaintext,
                                 expandTree: $expandTree)
    

                }
            } label: {
                PwNodeTreeItemView(node: node,
                                   targetNode: $targetNode,
                                   showPwNode: $showPwNode, 
                                   showPlaintext: $showPlaintext)

            }
        }
    }
}

private struct PwNodeTreeItemView: View {
    @EnvironmentObject var appState: AppState

    let node: PwNode
    @Binding var targetNode: PwNode?
    @Binding var showPwNode: Bool
    @Binding var showPlaintext: Bool

    var body: some View {
        return Text(node.name).font(.system(size: 18))
        .onTapGesture {
            if !node.isLeaf {
                return
            }
            targetNode = node
            withAnimation {
                showPlaintext = true
            }
        }
        .swipeActions(allowsFullSwipe: false) {
            Button(action: {
                handleGitRemove(node: node)
            }) {
                Image(systemName: "xmark.circle")
            }
            .tint(.red)

            Button(action: {
                targetNode = node
                withAnimation {
                    showPwNode = true
                }
            }) {
                Image(systemName: "pencil")
            }
            .tint(.blue)
        }
    }

    private func handleGitRemove(node: PwNode) {
        do {
            try Git.rmCommit(node: node)
            try appState.reloadGitTree()

        } catch {
            G.logger.error("\(error.localizedDescription)")
            try? Git.reset()
        }
    }
}
