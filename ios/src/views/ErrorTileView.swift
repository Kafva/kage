import SwiftUI

struct ErrorTileView: View {
    @Binding var currentError: String?

    var body: some View {
        TileView(iconName: "exclamationmark.circle") {
            Text(currentError ?? "No error").font(G.footnoteFont)
                .frame(alignment: .leading)
        }
        .foregroundColor(G.errorColor)
        .onTapGesture { currentError = nil }
        // Keep dimesions when hidden
        .opacity(currentError != nil ? 1.0 : 0.0)
    }
}
