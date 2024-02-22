import SwiftUI
import OSLog

let logger = Logger(subsystem: Bundle.main.bundleIdentifier!,
                    category: "generic")

// The remote IP should be configurable
// The remote path on the server needs to be configured in the client


struct ContentView: View {
    let repo = FileManager.default.appDataDirectory.appending(path: "pw")
    let remote = "git://10.0.2.7/james"

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Clone repo")
            .onTapGesture {
                let intoC = repo.path().cString(using: .utf8)!
                let urlC = remote.cString(using: .utf8)!

                let r = ffi_git_clone(url: urlC, into: intoC);
                if r != 0 {
                    logger.error("git clone failed: \(r)")
                    return
                }
                logger.debug("git clone OK")
            }
        }
        .padding()
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

