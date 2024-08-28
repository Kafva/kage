import SwiftUI

struct PlaintextView: View {
    @EnvironmentObject var appState: AppState

    @Binding var showView: Bool
    @Binding var currentPwNode: PwNode?
    @State private var plaintext: String = ""
    @State private var hidePlaintext = true
    @State private var currentError: String?

    var body: some View {
        if let currentPwNode {
            VStack(alignment: .center, spacing: 10) {
                let title = currentPwNode.name
                Text(title)
                    .font(G.title2Font)
                    .padding(.bottom, 15)

                let value = hidePlaintext ? "••••••••" : plaintext
                Text(value)
                    .font(.body)  // Scaling size
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
                        Text("Close")
                    }
                    .padding(.leading, 20)

                    Spacer()

                    Button {
                        UIPasteboard.general.string = plaintext
                        G.logger.debug("Copied '\(title)' to clipboard")
                    } label: {
                        Text("Copy...")
                    }
                    .padding(.trailing, 20)
                }
                .font(.body)  // Scaling size

                if currentError != nil {
                    ErrorTileView(currentError: $currentError).padding(.top, 30)
                }
            }
        }
        else {
            EmptyView()
        }
    }

    private func dismiss() {
        currentPwNode = nil
        showView = false
    }

    private func handleShowPlaintext() {
        guard let currentPwNode else {
            G.logger.debug("No target node set")
            return
        }
        if !currentPwNode.isPassword {
            return
        }
        do {
            plaintext = try Age.decrypt(currentPwNode.url)
            if plaintext == "" {
                currentError = uiError("No data retrieved")
            }
            else {
                currentError = nil
                hidePlaintext = false
            }
        }
        catch {
            currentError = uiError("\(error.localizedDescription)")
        }
    }

}
