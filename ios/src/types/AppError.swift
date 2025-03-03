import Foundation

enum AppError: Error, LocalizedError, Equatable {
    case cStringError
    case invalidCommit
    case ageError(String)
    case gitError(String)
    case invalidNodePath(String)
    case invalidPasswordFormat

    var errorDescription: String? {
        switch self {
        case .invalidCommit:
            return "Invalid commit metadata"
        case .cStringError:
            return "Cstring conversion failure"
        case .ageError(let msg):
            return String(localized: "Cryptographic error: \(msg)")
        case .gitError(let msg):
            return "Git error: \(msg)"
        case .invalidNodePath(let msg):
            return String(localized: "Invalid node: \(msg)")
        case .invalidPasswordFormat:
            return String(localized: "Invalid password format")
        }
    }
}
