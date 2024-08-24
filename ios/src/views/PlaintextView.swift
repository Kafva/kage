import SwiftUI

struct PlaintextView: View {
    @EnvironmentObject var appState: AppState

    @Binding var showView: Bool
    @Binding var currentPwNode: PwNode?
    @State private var plaintext: String = ""
    @State private var hidePlaintext = true

    var body: some View {
        if let currentPwNode {
            VStack(alignment: .center, spacing: 10) {
                let title = currentPwNode.name
                Text(title).font(.title2)  // Scaling
                    .underline(color: .accentColor)
                    .padding(.bottom, 10)

                let value = hidePlaintext ? "••••••••" : plaintext
                Text(value)
                    .font(.body)  // Scaling
                    .bold()
                    .monospaced()
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 30)
                    .onTapGesture {
                        hidePlaintext.toggle()
                    }

                HStack {
                    Button(action: dismiss) {
                        Label("Close", systemImage: "")
                    }
                    .padding(.leading, 20)

                    Spacer()

                    Button {
                        UIPasteboard.general.string = plaintext
                        G.logger.debug("Copied '\(title)' to clipboard")
                    } label: {
                        Label("Copy...", systemImage: "")
                    }
                    .padding(.trailing, 20)
                }
                .font(.subheadline)  // Scaling
            }
            .onAppear {
                handleShowPlaintext()
            }
        }
        else {
            EmptyView()
        }
    }

    private func dismiss() {
        withAnimation {
            currentPwNode = nil
            showView = false
        }
    }

    private func handleShowPlaintext() {
        guard let currentPwNode else {
            G.logger.debug("No target node set")
            return
        }
        if !currentPwNode.isLeaf {
            return
        }
        do {
            plaintext = try Age.decrypt(currentPwNode.url)
        }
        catch {
            appState.uiError("\(error.localizedDescription)")
        }
    }

}
