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
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if s.isEmpty {
            return G.rootNodeName
        }
        return s
    }

    var relativePathNoExtension: String {
        relativePath.deletingSuffix(".age")
    }

    var isPassword: Bool {
        return url.path().hasSuffix(".age")
    }

    private static func checkComponent(name: String, expectPassword: Bool)
        throws
    {
        if name == G.gitDirName {
            throw AppError.invalidNodePath(
                "The root node name '\(G.gitDirName)' is dissallowed")
        }

        // Make sure that the .age suffix is correctly used
        if expectPassword && !name.hasSuffix(".age") {
            throw AppError.invalidNodePath(
                "Password node without '.age' suffix: '\(name)'")
        }
        if !expectPassword && name.hasSuffix(".age") {
            throw AppError.invalidNodePath(
                "Directory with '.age' suffix: '\(name)'")
        }

        // Dots are allowed, but not by themselves
        let regexName = /^[-_.@åäöÅÄÖa-zA-Z0-9+]{1,64}/

        if (try? regexName.wholeMatch(in: name)) == nil
            || name.starts(with: ".")
            || name == ".."
        {
            throw AppError.invalidNodePath("'\(name)'")
        }
    }

    /// Validate that the given node path is OK to be inserted, it may already exist
    static func check(url: URL) throws -> Self {
        guard let urlNoSuffix = URL(string: url.path().deletingSuffix(".age"))
        else {
            throw AppError.invalidNodePath("Bad URL: '\(url.path())'")
        }
        guard let urlSuffix = URL(string: urlNoSuffix.path() + ".age")
        else {
            throw AppError.invalidNodePath("Bad URL: '\(url.path())'")
        }
        let expectPassword = url.path().hasSuffix(".age")
        let name = url.lastPathComponent
        try checkComponent(name: name, expectPassword: true)

        while true {
            let parentURL = url.deletingLastPathComponent()

            // Each parent must exist
            if !FileManager.default.isDir(parentURL) {
                throw AppError.invalidNodePath(
                    "Missing parent path: '\(parentURL.path())'")
            }

            // Each parent must have a valid name
            let parentName = parentURL.lastPathComponent
            try checkComponent(name: parentName, expectPassword: false)

            if parentURL.standardizedFileURL.path() == G.gitDir.path()
                || parentURL.path() == "/"
                || parentURL.path().isEmpty
            {
                break
            }

        }

        // Make sure that files and folder nodes do not overlap
        if expectPassword && FileManager.default.isDir(urlNoSuffix) {
            throw AppError.invalidNodePath(
                "Password node conflict with existing folder: '\(urlNoSuffix)'")
        }
        if !expectPassword && FileManager.default.isFile(urlSuffix) {
            throw AppError.invalidNodePath(
                "Directory node conflict with existing file: '\(urlSuffix)'")
        }

        return PwNode(url: url.standardizedFileURL, children: [])
    }

    /// Does a node with the current name already exist
    func nameTaken() throws -> Bool {
        guard let urlNoSuffix = URL(string: url.path().deletingSuffix(".age"))
        else {
            throw AppError.invalidNodePath("Bad URL: '\(url.path())'")
        }

        return FileManager.default.exists(url)
            || FileManager.default.exists(urlNoSuffix)
    }

    static func loadRecursivelyFrom(_ fromDir: URL) throws -> Self {
        var children: [Self] = []

        for url in try FileManager.default.ls(fromDir) {
            let node: PwNode

            if FileManager.default.isDir(url) {
                node = try loadRecursivelyFrom(url)
            }
            else {
                // The components of the parent path are validated for each leaf
                // (TODO: pretty inefficient...)
                node = try check(url: url)
            }
            children.append(node)
        }

        return PwNode(url: fromDir.standardizedFileURL, children: children)
    }

    /// Retrieve a list of all folder paths in the tree
    func flatFolders() -> [PwNode] {
        if !FileManager.default.isDir(url) {
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
            if child.isPassword && onlyFolders {
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
