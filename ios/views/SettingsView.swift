import SwiftUI
import OSLog


struct SettingsView: View {
    @Binding var showView: Bool

    @AppStorage("remote") private var remote: String = ""
    @State private var origin: String = ""
    @State private var name: String = ""


    private var contentView: some View {
        Group {
            HStack {
                Text("Remote origin").frame(width: G.screenWidth*0.3, alignment: .leading)
                TextField("Required", text: $origin)
            }
            .padding(.bottom, 10)

            HStack {
                Text("Username").frame(width: G.screenWidth*0.3, alignment: .leading)
                TextField("Required", text: $name)
            }
            .padding(.bottom, 10)
        }
        .textFieldStyle(.roundedBorder)
        .onSubmit {
            if !origin.isEmpty && !name.isEmpty {
                remote = "git://\(origin)/\(name)"
            }
        }
        .onAppear {
            if remote.isEmpty {
                return
            }
            guard let idx = remote.lastIndex(of: "/") else {
                return
            }
            if idx == remote.startIndex || idx == remote.endIndex {
                G.logger.debug("invalid remote origin: \(remote)")
                return
            }

            let originStart = remote.index(remote.startIndex, offsetBy: "git://".count) 
            let originEnd = remote.index(before: idx)
            let nameStart = remote.index(after: idx)

            origin = String(remote[originStart...originEnd])
            name = String(remote[nameStart...])
        }
    }


    // remote address
    // re-sync from scratch
    // version
    // debugging: force offline/online
    // History (git log) view
    var body: some View {
        Form {
            let settingsHeader = Text("Settings").font(G.headerFont)
                                                 .padding(.bottom, 10)
                                                 .padding(.top, 20)
                                                 .textCase(nil)
            let versionHeader = Text("Version").font(G.headerFont)
                                               .textCase(nil)


            Section(header: settingsHeader) {
                contentView
            }

            Section(header: versionHeader) {
                Text(G.gitVersion).font(.system(size: 12)).foregroundColor(.gray)
            }
            Section {
                Button(action: { withAnimation { showView = false } } ) {
                    Text("Dismiss").bold().font(.system(size: 18))
                }
                .padding([.top, .bottom], 5)
            }
        }
    }
}

