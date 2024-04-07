import Foundation
import SwiftUI

struct PwNode: Identifiable {
    let id = UUID()
    let url: URL
    let children: [PwNode]?

    var name: String {
         let name = url.deletingPathExtension().lastPathComponent
         // TODO: dissallow gitDir name
         if name == G.gitDir.lastPathComponent {
             return G.rootNodeName
         }
         return name
    }

    /// Path relative to git root
    var relativePath: String {
        let s = url.path().deletingPrefix(G.gitDir.path())
        if s.isEmpty {
            return G.rootNodeName
        }
        return s.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
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


    /// Retreive a list of all folder paths in the tree
    func flatFolders() -> [PwNode] {
        if self.isLeaf {
            return []
        }

        let node = PwNode(url: self.url, children: [])
        var folders: [PwNode] = [node]

        for child in children ?? [] {
            folders.append(contentsOf: child.flatFolders())
        }

        return folders
    }

    /// Returns a subset of the tree with paths to every node that matches
    /// `predicate`.
    func findChildren(predicate: String, onlyFolders: Bool = false) -> [PwNode] {
        var matches: [PwNode] = []
        let predicate = predicate.lowercased()

        for child in children ?? [] {
            if child.isLeaf && onlyFolders {
                continue
            }

            let childMatches = child.findChildren(predicate: predicate,
                                                  onlyFolders: onlyFolders)

            if childMatches.isEmpty {
                // Append the child with all its children if it matches the
                // predicate.
                if child.name.lowercased().contains(predicate) || predicate.isEmpty {
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
}

