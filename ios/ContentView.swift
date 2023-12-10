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
        }
        .padding()
        .onAppear {
            let res = rust_add(a: 1, b: 2)
            logger.debug("1 + 2 == \(res)")
        }
    }
}
