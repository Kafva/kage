import OSLog
import SwiftUI

struct HistoryView: View {
    @AppStorage("remote") private var remote: String = ""
    @EnvironmentObject var appState: AppState
    @State private var messages = [CommitInfo]()

    // TODO: Preview complete message and rev
    var body: some View {
        return List(messages) { m in
            VStack(alignment: .leading) {
                Text(m.summary).font(.body)
                Text(m.date).foregroundColor(.gray).font(.caption)
                if m.revstr.count != 40 {
                    // The `revstr` will be a prettified string for the
                    // remote HEAD instead of a hash, highlight it.
                    Text(m.revstr)
                        .foregroundColor(.accentColor)
                        .bold()
                        .font(.caption)
                }
            }
            .lineLimit(1)
            .truncationMode(.tail)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
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
