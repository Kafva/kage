import Foundation

extension URL {
    static func fromString(_ string: String) throws -> URL {
        guard let value = URL(string: string) else {
            throw AppError.urlError(string)
        }
        return value
    }
}
