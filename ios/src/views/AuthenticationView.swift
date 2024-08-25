import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var appState: AppState

    @Binding var showView: Bool
    @Binding var currentPwNode: PwNode?
    @State private var passphrase: String = ""

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
                    withAnimation {
                        submit()
                    }
                }
                .padding(.bottom, 20)

            HStack {
                Button("Cancel") {
                    appState.currentError = nil
                    currentPwNode = nil
                    hideKeyboard()
                    withAnimation {
                        showView = false
                    }
                }
                .padding(.leading, 10)
                Spacer()
                Button("Ok") {
                    withAnimation {
                        submit()
                    }
                }
                .padding(.trailing, 10)
            }
            .font(.body)  // Scaling size

            if appState.currentError != nil {
                ErrorTileView().padding(.top, 30)
            }
        }
    }

    private func submit() {
        do {
            try appState.unlockIdentity(passphrase: passphrase)
            appState.currentError = nil
            hideKeyboard()
        }
        catch {
            appState.uiError("\(error.localizedDescription)")
        }
    }
}
