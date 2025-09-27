import SwiftUI

extension EnvironmentValues {
    var screenDims: CGSize {
        get { self[ScreenDimsKey.self] }
        set { self[ScreenDimsKey.self] = newValue }
    }
}

private struct ScreenDimsKey: EnvironmentKey {
    static let defaultValue = CGSize()
}
