import OSLog
import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack {
            Text("TODO")
        }
        .onAppear {
            do {
                try Git.log()
            }
            catch {
                G.logger.error("\(error.localizedDescription)")
            }
        }
    }
}
