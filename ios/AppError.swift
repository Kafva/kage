import Foundation

enum AppError: Error, LocalizedError {
    case urlError(String)
    case cStringError

    var errorDescription: String? {
        switch self {
        case .urlError(let value):
            return "URL parsing failure: \(value)"
        case .cStringError:
            return "Cstring conversion failure"
        }
    }
}

