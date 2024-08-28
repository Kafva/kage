import SwiftUI

struct ErrorTileView: View {
    @Binding var currentError: String?

    var body: some View {
        TileView(iconName: "exclamationmark.circle") {
            Text(currentError ?? "Unknown error").font(G.captionFont)
                .foregroundColor(G.errorColor)
                .frame(alignment: .leading)
        }
        .onTapGesture { currentError = nil }
    }
}
