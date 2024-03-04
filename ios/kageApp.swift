import SwiftUI
import OSLog

@main
struct kageApp: App {
    @AppStorage("remote") private var remote: String = ""
    @StateObject private var appState: AppState = AppState()

    var body: some Scene {
        WindowGroup {
            AppView()
            .environmentObject(appState)
        }
    }
}
