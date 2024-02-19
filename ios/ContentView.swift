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
            Text("Initalize new repo")
            .onTapGesture {
                let appData = FileManager.default.appDataDirectory
                                                 .appending(path: "me")
                let repoPath = appData.path()
                let r = ffi_git_init(repoPath.cString(using: .utf8)!)
                if r != 0 {
                    logger.error("git init failed: \(r)")
                    return
                }
                logger.debug("git init OK")
            }
        }
        .padding()
        .onAppear {
            // let ptr = rust_identity()
            // let str = String(cString: ptr)
            // logger.debug("identity: \(str)")
            // rust_free_cstring(ptr)
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

