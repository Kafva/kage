import SwiftUI
import OSLog

struct AddView: View {
    @Binding var targetNode: PwNode?

    @State private var name = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var generate = true

    var body: some View {

        VStack {
            Text("Add a new password").font(.title)
            Spacer()
            TextField("Name", text: $name)

            Toggle(isOn: $generate) {
                Text("Autogenerate")
            }

            if !generate {
                let underlineColor = !password.isEmpty && password == confirmPassword ? 
                                      Color.green : Color.red
                SecureField("Password", text: $password)
                SecureField("Confirm password", text: $confirmPassword)
                Divider().frame(height: 2)
                         .overlay(underlineColor)
            }

            Button {
                if password == confirmPassword {
                    addPassword(password: password)
                } else {
                    G.logger.debug("Passwords do not match")
                }
            } label: {
                Image(systemName: "key.viewfinder").bold()
            }
        }
        .textFieldStyle(.roundedBorder)
        .frame(width: 0.8 * G.screenWidth)
    }

    private func addPassword(password: String) {
        let recipient = G.gitDir.appending(path: ".age-recipients")
        let outpath = G.gitDir.appending(path: "iOS.age")
        let _ = Age.encrypt(recipient: recipient,
                            outpath: outpath,
                            plaintext: password)
    }
}


