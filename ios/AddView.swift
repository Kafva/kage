import SwiftUI
import OSLog

struct AddView: View {
    @State private var path = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        Form {
            Section(header: Text("Path")) {
                TextField("Enter path", text: $path)
            }

            Section(header: Text("Password")) {
                SecureField("Enter password", text: $password)
            }

            Section(header: Text("Confirm Password")) {
                SecureField("Confirm password", text: $confirmPassword)
            }

            Section {
                Button("Submit") {
                    if password == confirmPassword {
                        addPassword(password: password)
                    } else {
                        G.logger.debug("Passwords do not match")
                    }
                }
            }
        }
    }

    private func addPassword(password: String) {
        let recipient = G.gitDir.appending(path: ".age-recipients")
        let outpath = G.gitDir.appending(path: "iOS.age")
        let _ = Age.encrypt(recipient: recipient,
                            outpath: outpath,
                            plaintext: password)

        G.logger.debug("Password submitted: \(password)")
    }
}


