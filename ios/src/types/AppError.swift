import Foundation

enum AppError: Error, LocalizedError {
    case urlError(String)
    case cStringError
    case ageError(String)
    case gitError(String)

    var errorDescription: String? {
        switch self {
        case .urlError(let value):
            return "URL parsing failure: \(value)"
        case .cStringError:
            return "Cstring conversion failure"
        case .ageError(let msg):
            return "Cryptographic error: \(msg)"
        case .gitError(let msg):
            return "Git error: \(msg)"
        }
    }
}
