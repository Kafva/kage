import OSLog
import SwiftUI

@_silgen_name("ffi_free_cstring")
func ffi_free_cstring(_ ptr: UnsafeMutablePointer<CChar>?)

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
