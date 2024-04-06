import Foundation

enum AppError: Error, LocalizedError {
    case urlError(String)
    case cStringError
    case ageError
    case gitError(CInt)

    var errorDescription: String? {
        switch self {
        case .urlError(let value):
            return "URL parsing failure: \(value)"
        case .cStringError:
            return "Cstring conversion failure"
        case .ageError:
            return "Cryptographic operation error"
        case .gitError(let code):
            return "Git error: \(code)"
        }
    }
}

