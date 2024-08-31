import SwiftUI

struct ErrorView: View {
    @Binding var currentError: String?

    var body: some View {
        VStack {
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
                }) {
                    Text("Dismiss").font(.body)  // Scaling size
                }
                Spacer()
            }
            .padding(.top, 30)
        }
        .padding([.leading, .trailing], 20)
    }
}
