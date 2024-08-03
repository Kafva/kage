import SwiftUI

struct ErrorView: View {
    @EnvironmentObject var appState: AppState

    @Binding var showView: Bool

    var body: some View {
        VStack {
            Spacer()
            Text("An error has occured")
                .foregroundColor(G.textColor)
                .bold()
                .font(.title2)  // Scaling size
                .padding(.bottom, 10)
                .padding(.top, 10)
            Text(appState.currentError ?? "No description available")
                .font(.body)  // Scaling size
                .foregroundColor(G.errorColor)

            HStack {
                Button(action: {
                    withAnimation {
                        showView = false
                        appState.currentError = nil
                    }
                }) {
                    Text("Dismiss").font(.body)  // Scaling size
                }
                Spacer()
            }
            .padding(.top, 30)
            Spacer()
        }
        .padding([.leading, .trailing], 20)
    }
}
