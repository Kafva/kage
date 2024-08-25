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
                Text(title)
                    .font(G.title2Font)
                    .padding(.bottom, 15)

                let value = hidePlaintext ? "••••••••" : plaintext
                Text(value)
                    .font(.body)  // Scaling
                    .bold()
                    .monospaced()
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 30)
                    .onTapGesture {
                        if plaintext.isEmpty {
                            handleShowPlaintext()
                        }
                        else {
                            hidePlaintext.toggle()
                        }
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

                if appState.currentError != nil {
                    ErrorTileView().padding(.top, 30)
                }
            }
        }
        else {
            EmptyView()
        }
    }

    private func dismiss() {
        appState.currentError = nil
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
            if plaintext == "" {
                appState.uiError("No data retrieved")
            }
            else {
                appState.currentError = nil
                hidePlaintext = false
            }
        }
        catch {
            appState.uiError("\(error.localizedDescription)")
        }
    }

}
