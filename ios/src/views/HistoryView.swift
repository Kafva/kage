import SwiftUI

struct HistoryView: View {
    @State private var commits = [CommitInfo]()

    var body: some View {
        return List(commits) { commit in
            NavigationLink(destination: HistoryItemView(commit: commit)) {
                VStack(alignment: .leading) {
                    Text(commit.summary).font(.body)
                    Text(commit.date).foregroundColor(.gray).font(.caption)
                    if commit.revstr.count != 40 {
                        // The `revstr` will be a prettified string for the
                        // remote HEAD instead of a hash, highlight it.
                        Text(commit.revstr)
                            .foregroundColor(.accentColor)
                            .bold()
                            .font(.caption)
                    }
                }
                .lineLimit(1)
                .truncationMode(.tail)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .onAppear {
            do {
                commits = try Git.log()
            }
            catch {
                LOG.error("\(error.localizedDescription)")
            }
        }
    }
}

private struct HistoryItemView: View {
    @Environment(\.screenDims) var screenDims
    let commit: CommitInfo

    var body: some View {
        let revColor: Color = commit.revstr.count != 40 ? .accentColor : .gray
        VStack(alignment: .leading, spacing: 5) {
            Text(commit.summary).font(.body).padding(
                .top, 0.1 * screenDims.height)
            Text(commit.date).foregroundColor(.gray).font(.caption).lineLimit(1)
            Text(commit.revstr).foregroundColor(revColor).font(.caption)
                .lineLimit(1)
            Spacer()
        }
        .padding([.leading, .trailing], 20)
    }
}
