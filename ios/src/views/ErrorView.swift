import SwiftUI

struct ErrorView: View {
    @Binding var currentError: String?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading) {
            Text("An error has occured")
                .foregroundColor(TEXT_COLOR)
                .bold()
                .font(TITLE2_FONT)
                .padding(.bottom, 10)
                .padding(.top, 10)
            Text(currentError ?? "No description available")
                .font(BODY_FONT)
                .foregroundColor(ERROR_COLOR)

            HStack {
                Button(action: {
                    currentError = nil
                    dismiss()
                }) {
                    Text("Dismiss").font(BODY_FONT)
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
