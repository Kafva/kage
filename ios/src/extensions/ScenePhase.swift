import SwiftUI

extension ScenePhase {
    var description: String {
        switch self {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .background:
            return "background"
        default:
            return "unknown"
        }
    }
}
