import Foundation

extension FileManager {
    var appDataDirectory: URL {
        let urls = self.urls(
            for: .documentDirectory,
            in: .userDomainMask)
        return urls[0]
    }

    func isDir(_ at: URL) -> Bool {
        return access(at, expectDirectory: true)
    }

    func isFile(_ at: URL) -> Bool {
        return access(at, expectDirectory: false)
    }

    func ls(_ at: URL) throws -> [URL] {
        return try self.contentsOfDirectory(at: at,
                                            includingPropertiesForKeys: nil,
                                            options: .skipsHiddenFiles)
    }

    func findFirstFile(_ at: URL) throws -> URL? {
        for entry in try FileManager.default.ls(at) {
            if FileManager.default.isFile(entry) {
                return entry
            }
            if let url = try findFirstFile(entry) {
                return url
            }
        }
        return nil
    }

    func mkdirp(_ at: URL) throws {
        if isDir(at) {
            return
        }
        return try self.createDirectory(at: at,
                                        withIntermediateDirectories: true)
    }

    private func access(_ at: URL, expectDirectory: Bool) -> Bool {
        var isDirectory: ObjCBool = true
        let atPath = at.path(percentEncoded: false)
        let exists = FileManager.default.fileExists(atPath: atPath,
                                                    isDirectory: &isDirectory)
        return exists && isDirectory.boolValue == expectDirectory
    }
}


