import Foundation

func guardLet<T>(_ value: T?, _ error: Error) throws -> T {
    guard let unwrappedValue = value else {
        throw error
    }
    return unwrappedValue
}

extension String {
    func toCString() throws -> [CChar] {
        return try guardLet(self.cString(using: .utf8), AppError.cStringError)
    }
}

extension URL {
    static func fromString(_ string: String) throws -> URL {
        return try guardLet(URL(string: string), AppError.urlError(string))
    }
}

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

    private func access(_ at: URL, expectDirectory: Bool) -> Bool {
        var isDirectory: ObjCBool = true
        let atPath = at.path(percentEncoded: false)
        let exists = FileManager.default.fileExists(atPath: atPath,
                                                    isDirectory: &isDirectory)
        return exists && isDirectory.boolValue == expectDirectory
    }
}

