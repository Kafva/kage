import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var appState: AppState

    @Binding var showView: Bool
    @State private var passphrase: String = ""

    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            Text("Authentication required")
            SecureField("Passphrase", text: $passphrase)
                .textFieldStyle(.roundedBorder)
                .onSubmit { submit() }
                .padding(.bottom, 20)
            HStack {
                Button("Cancel") {
                    showView = false
                }
                .padding(.leading, 10)
                Spacer()
                Button("Ok") {
                    submit()
                }
                .padding(.trailing, 10)
            }
            .font(G.bodyFont)
        }
    }

    private func submit() {
        do {
            try appState.unlockIdentity(passphrase: passphrase)
        }
        catch {
            G.logger.debug("Incorrect password")
            return
        }
    }
}
