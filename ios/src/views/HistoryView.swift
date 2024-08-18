import OSLog
import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var messages = [CommitInfo]()

    var body: some View {
        VStack {
            List(messages) { m in
                VStack(alignment: .leading) {
                    Text(m.summary).font(.body)
                    Text(m.date).foregroundColor(.gray).font(.caption)
                }
                .lineLimit(1)
                .truncationMode(.tail)
            }
        }
        .onAppear {
            do {
                messages = try Git.log()
            }
            catch {
                G.logger.error("\(error.localizedDescription)")
            }
        }
    }
}
