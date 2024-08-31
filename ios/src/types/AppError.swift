import Foundation

enum AppError: Error, LocalizedError, Equatable {
    case cStringError
    case invalidCommit
    case ageError(String)
    case gitError(String)
    case invalidNodePath(String)
    case invalidPasswordFormat
    case invalidRemoteAddress

    var errorDescription: String? {
        switch self {
        case .invalidCommit:
            return "Invalid commit metadata"
        case .invalidRemoteAddress:
            return "Invalid remote address"
        case .cStringError:
            return "Cstring conversion failure"
        case .ageError(let msg):
            return "Cryptographic error: \(msg)"
        case .gitError(let msg):
            return "Git error: \(msg)"
        case .invalidNodePath(let msg):
            return "Invalid node: \(msg)"
        case .invalidPasswordFormat:
            return "Invalid password format"
        }
    }
}
