import Foundation
import SwiftUI

struct PwNode: Identifiable, Hashable {
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

    /// Validate that the given node path is OK to be inserted
    static func loadValidatedFrom(
        name: String, relativePath: String, expectPassword: Bool,
        checkParents: Bool, allowNameTaken: Bool
    ) throws -> Self {
        if name.contains("/") {
            throw AppError.invalidNodePath("Node name cannot contain: '/'")
        }
        // XXX: We need to check for '..' before creating a URL
        if name.starts(with: ".") || name.hasSuffix(".")
            || relativePath.contains("./") || relativePath.contains("/.")
        {
            throw AppError.invalidNodePath(
                "Node name(s) cannot begin or end with: '.'")
        }
        let url = createURL(
            name: name, relativePath: relativePath,
            expectPassword: expectPassword)

        try checkLeaf(
            url: url, expectPassword: expectPassword,
            allowNameTaken: allowNameTaken)
        var parentURL = url

        // Do not iterate forever if we are in a bad state where gitDir is missing
        for _ in 0...G.maxTreeDepth {
            parentURL.deleteLastPathComponent()
            if parentURL.lastPathComponent == G.gitDirName {
                break
            }

            // Each parent must exist
            if !FileManager.default.isDir(parentURL) {
                throw AppError.invalidNodePath(
                    "Missing parent path: '\(parentURL.path())'")
            }

            // Each parent must have a valid name
            if !checkParents {
                continue
            }
            try checkLeaf(
                url: parentURL, expectPassword: false, allowNameTaken: true)

        }

        return PwNode(url: url.standardizedFileURL, children: [])
    }

    static func loadRecursivelyFrom(_ fromDir: URL) throws -> Self {
        var children: [Self] = []

        for url in try FileManager.default.ls(fromDir) {
            let node: PwNode
            let expectPassword = !FileManager.default.isDir(url)

            // Validate every leaf node as we traverse the tree
            try checkLeaf(
                url: url, expectPassword: expectPassword, allowNameTaken: true)

            if expectPassword {
                node = PwNode(url: url.standardizedFileURL, children: [])
            }
            else {
                node = try loadRecursivelyFrom(url)
            }
            children.append(node)
        }

        return PwNode(url: fromDir.standardizedFileURL, children: children)
    }

    static func createURL(
        name: String, relativePath: String, expectPassword: Bool
    ) -> URL {
        return G.gitDir.appending(
            path: "\(relativePath)/\(name)\(expectPassword ? ".age" : "")"
        ).standardizedFileURL
    }

    private static func checkLeaf(
        url: URL, expectPassword: Bool, allowNameTaken: Bool
    )
        throws
    {
        let name = url.lastPathComponent
        if name.isEmpty || name == ".age" || name == G.gitDirName {
            throw AppError.invalidNodePath("No name provided")
        }

        guard let urlNoSuffix = URL(string: url.path().deletingSuffix(".age"))
        else {
            throw AppError.invalidNodePath("Bad URL: '\(url.path())'")
        }
        guard let urlSuffix = URL(string: urlNoSuffix.path() + ".age")
        else {
            throw AppError.invalidNodePath("Bad URL: '\(url.path())'")
        }

        // The name should not contain '.age' after we strip away the suffix
        if urlNoSuffix.lastPathComponent.hasSuffix(".age") {
            throw AppError.invalidNodePath(
                "Node name cannot end with '.age': '\(name)'")
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

        // Checks for '..' need to be done before this since we receive a URL
        // (which resolves '..') as input.
        let regexName = /^[-_.@åäöÅÄÖa-zA-Z0-9+]{1,64}$/
        if (try? regexName.wholeMatch(in: name)) == nil {
            throw AppError.invalidNodePath("Bad name: '\(name)'")
        }

        if allowNameTaken {
            // Make sure that files and folder nodes do not overlap
            if expectPassword && FileManager.default.isDir(urlNoSuffix) {
                throw AppError.invalidNodePath(
                    "Password node conflict with existing folder: '\(urlNoSuffix.path())'"
                )
            }
            if !expectPassword && FileManager.default.isFile(urlSuffix) {
                throw AppError.invalidNodePath(
                    "Directory node conflict with existing file: '\(urlSuffix.path())'"
                )
            }
        }
        else if FileManager.default.exists(urlSuffix)
            || FileManager.default.exists(urlNoSuffix)
        {
            throw AppError.invalidNodePath("Name already taken: '\(name)'")
        }
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

    /// Returns the subset of the tree that matches `predicate`.
    /// Note: all children (recursively) of a node are included if a node
    /// matches the predicate.
    func findChildren(predicate: String) -> [PwNode] {
        // Include all of the children if there is no query
        if predicate.isEmpty {
            return children ?? []
        }

        var matches: [PwNode] = []
        let predicate = predicate.lowercased()

        // If the parent does not match the predicate, check each child
        for child in children ?? [] {
            if child.name.lowercased().contains(predicate) {
                // Include everything beneath a matching child
                matches.append(child)
                continue
            }

            // Check children recursively if the current child was not a match
            let childMatches = child.findChildren(predicate: predicate)

            // Include the child with the subset of the child nodes that match the query
            if !childMatches.isEmpty {
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
