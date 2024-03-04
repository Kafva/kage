import SwiftUI
import OSLog

@main
struct kageApp: App {
    @AppStorage("remote") private var remote: String = ""
    @StateObject private var appState: AppState = AppState()

    var body: some Scene {
        WindowGroup {
            AppView()
            .onAppear {
                if remote.isEmpty {
#if targetEnvironment(simulator)
                    remote = "git://127.0.0.1/james"
#else
                    remote = "git://10.0.1.8/james"
#endif
                }
            }
            .environmentObject(appState)
        }
    }
}
