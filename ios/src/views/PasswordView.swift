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
            submitText = String(localized: "Copy…")
            dismissText = String(localized: "Dismiss")
            headerText = node.name
        }
        else {
            submitText = "Ok"
            dismissText = String(localized: "Cancel")
            headerText = String(localized: "Authentication required")
        }

        return VStack(alignment: .center) {
            Text(headerText).font(TITLE2_FONT)
                .padding(.bottom, 10)
                .textCase(nil)

            if appState.identityIsUnlocked {
                Text(hidePlaintext ? "••••••••" : plaintext)
                    .font(TITLE3_FONT)
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
                        .font(TITLE3_FONT)
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
            .font(BODY_FONT)
            .padding(.top, 30)

            ErrorTileView(currentError: $currentError).padding(.top, 30)
        }
        .frame(width: 0.8 * SCREEN_WIDTH, height: SCREEN_HEIGHT)
        .navigationBarHidden(true)
    }

    private func setPlaintext() {
        if !plaintext.isEmpty {
            return
        }

        do {
            plaintext = try Age.decrypt(node.path)
            if plaintext.isEmpty {
                currentError = uiError("No data retrieved")
            }
            else {
                currentError = nil
            }
        }
        catch {
            currentError = uiError(error.localizedDescription)
        }
    }

    private func handleSubmit() {
        if !appState.identityIsUnlocked {
            do {
                try appState.unlockIdentity(passphrase: passphrase)
                currentError = nil
                // XXX: Do not keep the correct passphrase around, we do not want it
                // to be lying around after the unlock timeout
                passphrase = ""
                hideKeyboard()
            }
            catch {
                currentError = uiError(error.localizedDescription)
                return
            }
        }

        setPlaintext()
        if currentError == nil {
            UIPasteboard.general.string = plaintext
            LOG.debug("Copied '\(node.name)' to clipboard")
        }
    }

    private func handleShowPlaintext() {
        setPlaintext()
        if currentError == nil {
            hidePlaintext = false
        }
    }
}
