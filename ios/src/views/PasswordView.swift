import SwiftUI

struct PasswordView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var node: PwNode
    @State private var plaintext: String = ""
    @State private var hidePlaintext = true
    @State private var currentError: String?
    @State private var passphrase: String = ""

    var body: some View {
        let submitText: String
        let dismissText: String
        let headerText: String

        if appState.identityIsUnlocked {
            submitText = "Copy..."
            dismissText = "Dismiss"
            headerText = node.name
        }
        else {
            submitText = "Ok"
            dismissText = "Cancel"
            headerText = "Authentication required"
        }

        return VStack(alignment: .center) {
            Text(headerText).font(G.title2Font)
                .padding(.bottom, 10)
                .textCase(nil)

            if appState.identityIsUnlocked {
                Text(hidePlaintext ? "••••••••" : plaintext)
                    .font(G.title3Font)
                    .bold()
                    .monospaced()
                    .foregroundColor(.accentColor)
                    .onTapGesture {
                        if plaintext.isEmpty {
                            handleShowPlaintext()
                        }
                        else {
                            hidePlaintext.toggle()
                        }
                    }
            }
            else {
                VStack {
                    SecureField("Password", text: $passphrase)
                        .font(G.title3Font)
                        // The .oneTimeCode content appears to consistently disable all password etc.
                        // suggestions in the on-screen keyboard, for now (iOS 18.0).
                        .textContentType(.oneTimeCode)
                        .onSubmit {
                            handleSubmit()
                        }
                    Divider().frame(height: 1).overlay(.gray).opacity(0.8)
                        .padding(.top, 5)
                }
            }

            HStack {
                Button(dismissText) {
                    hideKeyboard()
                    dismiss()
                }
                .padding(.leading, 10)
                .buttonStyle(.bordered)

                Spacer()

                Button(submitText) {
                    handleSubmit()
                }
                .padding(.trailing, 10)
                .buttonStyle(.bordered)
                .tint(.accentColor)
            }
            .font(.body)  // Scaling size
            .padding(.top, 30)

            ErrorTileView(currentError: $currentError).padding(.top, 30)
        }
        .frame(width: 0.8 * G.screenWidth, height: G.screenHeight)
        .navigationBarHidden(true)
    }

    private func handleSubmit() {
        if appState.identityIsUnlocked {
            UIPasteboard.general.string = plaintext
            G.logger.debug("Copied '\(node.name)' to clipboard")
        }
        else {
            do {
                try appState.unlockIdentity(passphrase: passphrase)
                currentError = nil
                hideKeyboard()
            }
            catch {
                currentError = uiError("\(error.localizedDescription)")
            }
        }
    }

    private func handleShowPlaintext() {
        if !node.isPassword {
            G.logger.error(
                "Cannot show password for non-password node: '\(node.name)'")
            return
        }
        do {
            plaintext = try Age.decrypt(node.url)
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
