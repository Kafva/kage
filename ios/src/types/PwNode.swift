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

    var parentName: String {
        if self.name == G.gitDirName {
            return G.rootNodeName
        }
        return url.deletingLastPathComponent().lastPathComponent
    }

    var parentRelativePath: String {
        if url.lastPathComponent == G.gitDirName
            || url.lastPathComponent == G.rootNodeName
        {
            return G.rootNodeName
        }
        else {
            let parentURL = url.deletingLastPathComponent()
            return PwNode(url: parentURL, children: []).relativePath
        }
    }

    /// Path relative to git root
    var relativePath: String {
        let s = url.standardizedFileURL.path().deletingPrefix(G.gitDir.path())
        if s.isEmpty {
            return G.rootNodeName
        }
        return s.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    var relativePathNoExtension: String {
        relativePath.deletingSuffix(".age")
    }

    var isLeaf: Bool {
        return (children ?? []).isEmpty
    }

    var isDir: Bool {
        return FileManager.default.isDir(url)
    }

    /// Load a node from the given folder path, the node is allowed to already exist.
    static func loadFrom(
        name: String,
        relativeFolderPath: String,
        isDir: Bool
    ) throws -> Self {

        if name == G.gitDirName {
            throw AppError.invalidNodePath(
                "The root node name '\(G.gitDirName)' is dissallowed")
        }

        if name.hasSuffix(".age") {
            throw AppError.invalidNodePath("The '.age' suffix is dissallowed")
        }

        let regex = /^[-_.@\/a-zA-Z0-9+]{1,64}/

        if (try? regex.wholeMatch(in: name)) == nil {
            throw AppError.invalidNodePath("Invalid node name: '\(name)'")
        }

        let parentURL = G.gitDir.appending(path: relativeFolderPath)

        // Parent must exist
        if !FileManager.default.isDir(parentURL) {
            throw AppError.invalidNodePath(
                "Missing parent path: '\(relativeFolderPath)'")
        }

        let urlFile = parentURL.appending(path: name + ".age")
        let urlDir = parentURL.appending(path: name)

        // Make sure that files and folder nodes do not overlap
        if !isDir && FileManager.default.isDir(urlDir) {
            throw AppError.invalidNodePath(
                "Password node conflict with existing folder: '\(urlDir)'")
        }
        if isDir && FileManager.default.isFile(urlFile) {
            throw AppError.invalidNodePath(
                "Directory node conflict with existing file: '\(urlFile)'")
        }

        return PwNode(url: isDir ? urlDir : urlFile, children: [])
    }

    static func loadFrom(_ fromDir: URL) throws -> Self {
        var children: [Self] = []

        for url in try FileManager.default.ls(fromDir) {
            let node =
                FileManager.default.isDir(url)
                ? try loadFrom(url) : PwNode(url: url, children: nil)

            children.append(node)
        }

        return PwNode(url: fromDir, children: children)
    }

    /// Retrieve a list of all folder paths in the tree
    func flatFolders() -> [PwNode] {
        if !self.isDir {
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
    func findChildren(predicate: String, onlyFolders: Bool = false) -> [PwNode]
    {
        var matches: [PwNode] = []
        let predicate = predicate.lowercased()

        for child in children ?? [] {
            if child.isLeaf && onlyFolders {
                continue
            }

            let childMatches = child.findChildren(
                predicate: predicate,
                onlyFolders: onlyFolders)

            if childMatches.isEmpty {
                // Append the child with all its children if it matches the
                // predicate.
                if child.name.lowercased().contains(predicate)
                    || predicate.isEmpty
                {
                    matches.append(child)
                }
            }
            else {
                // Append the child with a subset of its own children if one of
                // its children matched the predicate.
                let subsetChild = PwNode(url: child.url, children: childMatches)
                matches.append(subsetChild)
            }
        }

        return matches
    }
}

enum PwNodeType: String, CaseIterable, Identifiable {
    case password, folder
    var id: Self { self }
}
