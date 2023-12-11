import SwiftUI
import OSLog

let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                category: "generic")

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            .onTapGesture {
                let appData = FileManager.default.appDataDirectory
                                                 .appending(path: "me")
                let cStr = appData.path().cString(using: .utf8)!
                rust_git_init(cStr)
                logger.debug("git init done")
            }
        }
        .padding()
        .onAppear {
            let ptr = rust_identity()
            let str = String(cString: ptr)
            logger.debug("identity: \(str)")
            rust_free_cstring(ptr)
        }
    }
}

extension FileManager {
    var appDataDirectory: URL {
        let urls = self.urls(
            for: .documentDirectory,
            in: .userDomainMask)
        return urls[0]
    }
}

