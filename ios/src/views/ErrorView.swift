import SwiftUI

struct ErrorView: View {
    @Binding var currentError: String?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading) {
            Text("An error has occured")
                .foregroundColor(G.textColor)
                .bold()
                .font(.title2)  // Scaling size
                .padding(.bottom, 10)
                .padding(.top, 10)
            Text(currentError ?? "No description available")
                .font(.body)  // Scaling size
                .foregroundColor(G.errorColor)

            HStack {
                Button(action: {
                    currentError = nil
                    dismiss()
                }) {
                    Text("Dismiss").font(.body)  // Scaling size
                }
                .buttonStyle(.bordered)
                Spacer()
            }
            .padding(.top, 30)
        }
        .padding([.leading, .trailing], 25)
        .navigationBarHidden(true)
    }
}
