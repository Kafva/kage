import OSLog
import SwiftUI

@main
struct kageApp: App {
    @Environment(\.scenePhase) var scenePhase

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
        .onChange(of: scenePhase, initial: true) { oldPhase, newPhase in
            if oldPhase == newPhase {
                return
            }
            G.logger.debug(
                "scene: \(oldPhase.description) -> \(newPhase.description)")


            // Check if the identity should be re-locked every time the app moves
            // in or out of the background.
            if oldPhase != .background && newPhase != .background {
                return
            }

            guard let identityUnlockedAt = appState.identityUnlockedAt else {
                return
            }

            let seconds = identityUnlockedAt.distance(to: .now)
            if seconds > G.autoLockSeconds {
                G.logger.debug(
                    "Locking identity due to timeout: [\(seconds.rounded()) sec]"
                )
                try? appState.lockIdentity()
            }
        }
    }
}
