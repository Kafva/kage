import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var appState: AppState

    @Binding var showView: Bool
    @Binding var currentPwNode: PwNode?
    @State private var passphrase: String = ""
    @State private var currentError: String?

    var body: some View {
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
                    submit()
                }
                .padding(.bottom, 20)

            HStack {
                Button("Cancel") {
                    currentPwNode = nil
                    hideKeyboard()
                    showView = false
                }
                .padding(.leading, 10)
                Spacer()
                Button("Ok") {
                    submit()
                }
                .padding(.trailing, 10)
            }
            .font(.body)  // Scaling size

            if currentError != nil {
                ErrorTileView(currentError: $currentError).padding(.top, 30)
            }
        }
    }

    private func submit() {
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
