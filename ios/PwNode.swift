import Foundation

struct PwNode: Identifiable {
    let id = UUID()
    let url: URL
    let children: [PwNode]?

    var name: String {
         return url.deletingPathExtension().lastPathComponent
    }

    var isLeaf: Bool {
        return (children ?? []).isEmpty
    }

    static func loadFrom(_ fromDir: URL) throws -> Self {
        var children: [Self] = []

        for url in try FileManager.default.ls(fromDir) {
            let node = FileManager.default.isDir(url) ?
                                try loadFrom(url) :
                                PwNode(url: url, children: nil)

            children.append(node)
        }

        return PwNode(url: fromDir, children: children)
    }

    /// Returns a subset of the tree with paths to every node that matches
    /// `predicate`.
    func findChildren(predicate: String) -> [PwNode] {
        var matches: [PwNode] = []
        let predicate = predicate.lowercased()

        for child in children ?? [] {
            let childMatches = child.findChildren(predicate: predicate)

            if childMatches.isEmpty {
                // Append the child with all its children if it matches the
                // predicate.
                if child.name.lowercased().contains(predicate) {
                    matches.append(child)
                }
            } else {
                // Append the child with a subset of its own children if one of
                // its children matched the predicate.
                let subsetChild = PwNode(url: child.url, children: childMatches)
                matches.append(subsetChild)
            }
        }

        return matches
    }

    func getPlaintext() -> String? {
        if !self.isLeaf {
            return nil
        }
        return Age.decrypt(self.url)
    }
}

