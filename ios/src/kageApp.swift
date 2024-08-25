import BackgroundTasks
import OSLog
import SwiftUI

@main
struct kageApp: App {
    @Environment(\.scenePhase) var scenePhase
    /// Needs to match an identifier in the BGTaskSchedulerPermittedIdentifiers array
    /// of the Info.plist in the project.
    private static let appRefreshIdentifier =
        "kafva.kage.notifications.scheduler"

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
        .backgroundTask(.appRefresh(Self.appRefreshIdentifier)) {
            G.logger.info("Background task triggered!!")
            await lockIdentity()
        }
        .onChange(of: scenePhase, initial: true) { oldPhase, newPhase in
            G.logger.debug(
                "scene: \(oldPhase.description) -> \(newPhase.description)")

            if newPhase == .background && appState.identityUnlockedAt != nil {
                G.logger.debug("Scheduling background task")
                scheduleAppRefreshTask()
            }
        }
    }

    private func scheduleAppRefreshTask() {
        let request = BGAppRefreshTaskRequest(
            identifier: Self.appRefreshIdentifier
        )

        request.earliestBeginDate = Date.now

        do {
            try BGTaskScheduler.shared.submit(request)
            G.logger.info(
                "Submitted background task with id: \(request.identifier)")
        }
        catch let error {
            G.logger.error(
                "Error submitting background task: \(error.localizedDescription)"
            )
        }
    }

    func lockIdentity() async {
        G.logger.info("Background task triggered")
        try? appState.lockIdentity()

        // guard let identityUnlockedAt = appState.identityUnlockedAt else {
        //     return
        // }

        // let seconds = identityUnlockedAt.distance(to: .now)
        // if seconds > G.autoLockSeconds {
        //     G.logger.debug(
        //         "Locking identity due to timeout: [\(seconds.rounded()) sec]"
        //     )
        //     try? appState.lockIdentity()
        // }

    }
}
