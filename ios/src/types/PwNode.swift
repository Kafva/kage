import Foundation
import SwiftUI
import System

struct PwNode: Identifiable, Hashable {
    let id = UUID()
    /// `URL` objects are always url encoded, we have no need for this,
    /// use the `FilePath` representation instead.
    let path: FilePath
    let children: [PwNode]?

    /// Name without file extension
    var name: String {
        let name = (path.lastComponent?.string ?? "").deletingSuffix(".age")
        if name == G.gitDirName {
            return G.rootNodeName
        }
        return name
    }

    var parentName: String {
        if self.name == G.gitDirName {
            return G.rootNodeName
        }
        return path.removingLastComponent().lastComponent?.string ?? ""
    }

    var parentRelativePath: String {
        if parentName == G.gitDirName || name == G.rootNodeName {
            return G.rootNodeName
        }
        else {
            return relativePath
        }
    }

    /// Path relative to git root
    var relativePath: String {
        let s = path.string
            .deletingPrefix(G.gitDir.string)
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
        return path.string.hasSuffix(".age")
    }

    /// Validate that the given node path is OK to be inserted
    static func loadValidatedFrom(
        name: String,
        relativePath: String,
        expectPassword: Bool,
        checkParents: Bool,
        allowNameTaken: Bool
    ) throws -> Self {
        if name.contains("/") {
            throw AppError.invalidNodePath("Node name cannot contain: '/'")
        }
        // Check for '..' before creating a filepath
        if name.hasPrefix(".") || name.hasSuffix(".")
            || relativePath.hasPrefix(".") || relativePath.hasSuffix(".")
            || relativePath.contains("./") || relativePath.contains("/.")
        {
            throw AppError.invalidNodePath(
                "Node name(s) cannot begin or end with: '.'")
        }
        let path = createAbsPath(
            name: name,
            relativePath: relativePath,
            expectPassword: expectPassword)

        try checkLeaf(
            path: path,
            expectPassword: expectPassword,
            allowNameTaken: allowNameTaken)
        var parentPath = path

        // Do not iterate forever if we are in a bad state where gitDir is missing
        for _ in 0...G.maxTreeDepth {
            parentPath.removeLastComponent()
            let parentName = parentPath.lastComponent?.string ?? ""
            if parentName == G.gitDirName {
                break
            }

            // Each parent must exist
            if !FileManager.default.isDir(parentPath) {
                throw AppError.invalidNodePath(
                    "Missing parent path: '\(parentPath.string)'")
            }

            // Each parent must have a valid name
            if !checkParents {
                continue
            }
            try checkLeaf(
                path: parentPath, expectPassword: false, allowNameTaken: true)

        }

        return PwNode(path: path, children: [])
    }

    static func loadRecursivelyFrom(_ fromDir: FilePath) throws -> Self {
        var children: [Self] = []

        for path in try FileManager.default.ls(fromDir) {
            let node: PwNode
            let expectPassword = !FileManager.default.isDir(path)

            // Validate every leaf node as we traverse the tree
            try checkLeaf(
                path: path, expectPassword: expectPassword, allowNameTaken: true
            )

            if expectPassword {
                node = PwNode(path: path, children: [])
            }
            else {
                node = try loadRecursivelyFrom(path)
            }
            children.append(node)
        }

        return PwNode(path: fromDir, children: children)
    }

    static func createAbsPath(
        name: String, relativePath: String, expectPassword: Bool
    ) -> FilePath {
        return G.gitDir.appending(
            "\(relativePath)/\(name)\(expectPassword ? ".age" : "")"
        )
    }

    private static func checkLeaf(
        path: FilePath, expectPassword: Bool, allowNameTaken: Bool
    )
        throws
    {
        let name = path.lastComponent?.string ?? ""
        if name.isEmpty || name == ".age" || name == G.gitDirName {
            throw AppError.invalidNodePath("No name provided")
        }

        let filepathNoSuffix = FilePath(path.string.deletingSuffix(".age"))
        let filepathSuffix = FilePath(filepathNoSuffix.string + ".age")

        // The name should not contain '.age' after we strip away the suffix
        if filepathNoSuffix.string.hasSuffix(".age") {
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

        let regexName = /^[-_.@åäöÅÄÖa-zA-Z0-9+]{1,64}$/
        if (try? regexName.wholeMatch(in: name)) == nil {
            throw AppError.invalidNodePath("Bad name: '\(name)'")
        }

        if allowNameTaken {
            // Make sure that files and folder nodes do not overlap
            if expectPassword && FileManager.default.isDir(filepathNoSuffix) {
                throw AppError.invalidNodePath(
                    "Password node conflict with existing folder: '\(filepathNoSuffix)'"
                )
            }
            if !expectPassword && FileManager.default.isFile(filepathSuffix) {
                throw AppError.invalidNodePath(
                    "Directory node conflict with existing file: '\(filepathSuffix)'"
                )
            }
        }
        else if FileManager.default.exists(filepathSuffix)
            || FileManager.default.exists(filepathNoSuffix)
        {
            throw AppError.invalidNodePath("Name already taken: '\(name)'")
        }
    }

    /// Retrieve a list of all folder paths in the tree
    func flatFolders() -> [PwNode] {
        if !FileManager.default.isDir(path) {
            return []
        }

        let node = PwNode(path: self.path, children: [])
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
                let subsetChild = PwNode(
                    path: child.path, children: childMatches)
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
