import SwiftUI

@main
struct kageApp: App {
    @AppStorage("tint") private var tint: String = ""

    var body: some Scene {
        WindowGroup {
            AppView()
            .tint(tint == "Red" ? Color.red : Color.blue)
        }
    }
}
