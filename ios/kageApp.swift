import SwiftUI
import OSLog

let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                    category: "generic")

@main
struct kageApp: App {
    @AppStorage("tint") private var tint: String = ""
    @AppStorage("remote") private var remote: String = ""

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
            .tint(tint == "Red" ? Color.red : Color.blue)
        }
    }
}
