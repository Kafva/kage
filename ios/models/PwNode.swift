import Foundation
import SwiftUI

struct PwNode: Identifiable {
    let id = UUID()
    let url: URL
    let children: [PwNode]?

    var name: String {
         let name = url.deletingPathExtension().lastPathComponent
         if name == G.gitDirName {
             return G.rootNodeName
         }
         return name
    }

    var parentRelativePath: String {
        if url.lastPathComponent == G.gitDirName ||
           url.lastPathComponent == G.rootNodeName {
            return G.rootNodeName
        } else {
            let parentURL = url.deletingLastPathComponent()
            return PwNode(url: parentURL, children: []).relativePath
        }
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

    /// Create a new PwNode from a given name and folder path reletive to the
    /// git root. Will return nil if the object already exists in the git
    /// store.
    static func loadNewFrom(name: String,
                            relativeFolderPath: String,
                            isDir: Bool) -> Self? {
        if name == G.gitDirName ||
           name.isEmpty ||
           name.hasSuffix(".age") ||
           !relativeFolderPath.isPrintableASCII ||
           !name.isPrintableASCII {
            return nil
        }

        let parentURL = G.gitDir.appending(path: relativeFolderPath)

        // Parent must exist
        if !FileManager.default.isDir(parentURL) {
            G.logger.error("Missing parent path: '\(relativeFolderPath)'")
            return nil
        }

        let urlFile = parentURL.appending(path: name + ".age")
        let urlDir = parentURL.appending(path: name)

        // New node is not allowed to already exist
        if FileManager.default.isFile(urlFile) {
            return nil
        }
        if FileManager.default.isDir(urlDir) {
            return nil
        }

        return PwNode(url: isDir ? urlDir : urlFile, children: [])
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

