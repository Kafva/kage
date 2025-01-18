import Foundation
import System

extension FileManager {
    var appDataDirectory: FilePath {
        let urls = self.urls(
            for: .documentDirectory,
            in: .userDomainMask)
        return FilePath(urls[0].path(percentEncoded: false))
    }

    func isDir(_ at: FilePath) -> Bool {
        return access(at, expectDirectory: true)
    }

    func isFile(_ at: FilePath) -> Bool {
        return access(at, expectDirectory: false)
    }

    func exists(_ at: FilePath) -> Bool {
        return FileManager.default.fileExists(atPath: at.string)
    }

    func ls(_ at: FilePath) throws -> [FilePath] {
        return try self.contentsOfDirectory(atPath: at.string).filter {
            !$0.starts(with: ".")
        }.map { at.appending($0) }
    }

    func findFiles(_ at: FilePath) throws -> [FilePath] {
        var files: [FilePath] = []
        for entry in try FileManager.default.ls(at) {
            if FileManager.default.isFile(entry) {
                files.append(entry)
            }
            else {
                let fileUrls = try findFiles(entry)
                files.append(contentsOf: fileUrls)
            }
        }
        return files
    }

    func findFirstFile(_ at: FilePath) throws -> FilePath? {
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

    // periphery: ignore
    func mkdirp(_ at: FilePath) throws {
        if isDir(at) {
            return
        }
        return try self.createDirectory(
            atPath: at.string,
            withIntermediateDirectories: true)
    }

    private func access(_ at: FilePath, expectDirectory: Bool) -> Bool {
        var isDirectory: ObjCBool = true
        let exists = FileManager.default.fileExists(
            atPath: at.string,
            isDirectory: &isDirectory)
        return exists && isDirectory.boolValue == expectDirectory
    }
}
