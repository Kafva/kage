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
        let submitText = appState.identityIsUnlocked ? "Copy..." : "Ok"
        let dismissText = appState.identityIsUnlocked ? "Dismiss" : "Cancel"
        VStack(alignment: .center, spacing: 10) {
            if appState.identityIsUnlocked {
                plaintextView
            }
            else {
                authenticationView
            }

            HStack {
                Button(dismissText) {
                    hideKeyboard()
                    dismiss()
                }
                .padding(.leading, 10)
                Spacer()
                Button(submitText) {
                    handleSubmit()
                }
                .padding(.trailing, 10)

            }.font(.body)  // Scaling size

            if currentError != nil {
                ErrorTileView(currentError: $currentError).padding(.top, 30)
            }
        }
        .frame(width: 0.8 * G.screenWidth, height: G.screenHeight)
        .navigationBarHidden(true)
    }

    private var authenticationView: some View {
        VStack(alignment: .center) {
            Text("Authentication required")
                .font(G.title2Font)
                .padding(.bottom, 15)

            SecureField("Passphrase", text: $passphrase)
                .textFieldStyle(.roundedBorder)
                // The .oneTimeCode content appears to consistently disable all password etc.
                // suggestions in the on-screen keyboard, for now (iOS 18.0).
                .textContentType(.oneTimeCode)
                .onSubmit {
                    handleSubmit()
                }
                .padding(.bottom, 20)
        }
    }

    private var plaintextView: some View {
        VStack(alignment: .center, spacing: 10) {
            let title = node.name
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
        }
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
