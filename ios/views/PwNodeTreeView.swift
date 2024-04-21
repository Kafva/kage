import SwiftUI
import OSLog

struct PwNodeTreeView: View {
    @EnvironmentObject var appState: AppState

    @Binding var searchText: String

    @State private var isExpanded: Bool = false

    var body: some View {
        VStack {
            DisclosureGroup("Folder 1", isExpanded: $isExpanded) {
                VStack {
                    Text("aaaaaaaaaaaaaaaa")
                    Text("aaaaaaaaaaaaaaaa")
                    Text("aaaaaaaaaaaaaaaa")
                    Text("aaaaaaaaaaaaaaaa")
                    Text("aaaaaaaaaaaaaaaa")
                    DisclosureGroup("Folder 2", isExpanded: $isExpanded) {
                        Text("AAAAAAAAAAAAAAAA")
                        Text("AAAAAAAAAAAAAAAA")
                        Text("AAAAAAAAAAAAAAAA")
                    }
                }

            }

        }
    }

    private var searchResults: [PwNode] {
        if searchText.isEmpty {
            return appState.rootNode.children ?? []
        } else {
            return appState.rootNode.findChildren(predicate: searchText)
        }
    }

}
