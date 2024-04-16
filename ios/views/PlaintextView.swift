import SwiftUI

struct PlaintextView: View {
    @Binding var showPlaintext: Bool
    @Binding var targetNode: PwNode?
    @State private var plaintext: String = ""

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            let title = "\(targetNode?.name ?? "Plaintext")"
            Text(title)
                       .font(.system(size: 22))
                       .underline(color: .accentColor)

            Text(plaintext).bold().monospaced()
            .padding(.bottom, 20)

            Button {
                UIPasteboard.general.string = plaintext
                G.logger.debug("Copied '\(title)' to clipboard")
            } label: {
                Image(systemName: "doc.on.clipboard").bold()
            }
            .padding(.bottom, 10)
            .font(.system(size: 18))

            Button("Dismiss") {
                showPlaintext = false
            }
            .font(.system(size: 18))
        }
        .onAppear {
            handleShowPlaintext()
        }
    }


    private func handleShowPlaintext() {
        do {
            guard let targetNode else {
                G.logger.debug("No target node set")
                return
            }
            if !targetNode.isLeaf {
                return
            }

            plaintext = try Age.decrypt(targetNode.url)

        } catch {
            G.logger.error("\(error)")
        }
    }

}
