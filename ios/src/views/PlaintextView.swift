import SwiftUI

struct PlaintextView: View {
    @Binding var showView: Bool
    @Binding var targetNode: PwNode?
    @State private var plaintext: String = ""
    @State private var hidePlaintext = true

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            let title = "\(targetNode?.name ?? "Plaintext")"
            Text(title).font(.system(size: 22))
                .underline(color: .accentColor)
                .padding(.bottom, 10)

            let value = hidePlaintext ? "••••••••" : plaintext
            Text(value).bold()
                .monospaced()
                .foregroundColor(.accentColor)
                .padding(.bottom, 20).onTapGesture {
                    hidePlaintext.toggle()
                }
            Button {
                UIPasteboard.general.string = plaintext
                G.logger.debug("Copied '\(title)' to clipboard")
            } label: {
                Image(systemName: "doc.on.clipboard").bold()
            }
            .padding(.bottom, 10)
            .font(.system(size: 18))

            Button("Dismiss") {
                dismiss()
            }
            .font(.system(size: 18))
        }
        .onAppear {
            handleShowPlaintext()
        }
    }

    private func dismiss() {
        withAnimation {
            targetNode = nil
            showView = false
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

        }
        catch {
            G.logger.error("\(error.localizedDescription)")
        }
    }

}
