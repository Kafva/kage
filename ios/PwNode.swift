import Foundation

struct PwNode: Identifiable {
    let id = UUID()
    let url: URL
    let children: [PwNode]?

    var name: String {
         return url.deletingPathExtension().lastPathComponent
    }

    var isFile: Bool {
        return (children ?? []).isEmpty
    }

    static func loadChildren(_ fromDir: URL) throws -> Self {
        var children: [Self] = []

        for url in try FileManager.default.ls(fromDir) {
            let node = FileManager.default.isDir(url) ?
                                try loadChildren(url) :
                                PwNode(url: url, children: nil)

            children.append(node)
        }

        return PwNode(url: fromDir, children: children)
    }

    func findChildren(predicate: String) -> [PwNode] {
        var matches: [PwNode] = []
        let predicate = predicate.lowercased()
        for child in children ?? [] {
            // Append the child to `matches` if it is a leaf that matches the
            // predicate or if it has a child that matches the predicate
            if child.isFile {
                if child.name.lowercased().contains(predicate) {
                    matches.append(child)
                }

            } else {
                let childMatches = child.findChildren(predicate: predicate)
                if !childMatches.isEmpty {
                    matches.append(child)
                }
            }
        }

        return matches
    }

    func show() {
        if !self.isFile {
            return
        }

        let clock = ContinuousClock()
        let elapsed = clock.measure {
            LOGGER.info("Decryption: BEGIN")
            let plaintext = Age.decrypt(self.url)
            LOGGER.info("Decrypted: '\(plaintext)'")
        }
        LOGGER.info("Decryption: END [\(elapsed)]")
    }
}

