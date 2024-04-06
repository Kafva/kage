import Foundation

extension URL {
    static func fromString(_ string: String) throws -> URL {
        return try guardLet(URL(string: string), AppError.urlError(string))
    }
}

