import OSLog
import SwiftUI

@main
struct kageApp: App {
    @AppStorage("remote") private var remote: String = ""
    @StateObject private var appState: AppState = AppState()

    var body: some Scene {
        WindowGroup {
            AppView()
                .ignoresSafeArea()
                .autocorrectionDisabled()
                .autocapitalization(.none)
                // Default keyboard layout
                .keyboardType(.asciiCapable)
                // Avoid extra spacing below the toolbar
                .navigationBarTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .environmentObject(appState)
        }
    }
}
