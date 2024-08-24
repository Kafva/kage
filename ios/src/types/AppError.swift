import Foundation

enum AppError: Error, LocalizedError {
    case urlError(String)
    case cStringError
    case invalidCommit
    case ageError(String)
    case gitError(String)
    case passwordMismatch
    case invalidNodePath(String)

    var errorDescription: String? {
        switch self {
        case .urlError(let value):
            return "URL parsing failure: \(value)"
        case .invalidCommit:
            return "Invalid commit metadata"
        case .cStringError:
            return "Cstring conversion failure"
        case .ageError(let msg):
            return "Cryptographic error: \(msg)"
        case .gitError(let msg):
            return "Git error: \(msg)"
        case .passwordMismatch:
            return "Passwords do not match"
        case .invalidNodePath(let msg):
            return "Invalid node: \(msg)"
        }
    }
}
