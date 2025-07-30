import SwiftUI

struct ErrorTileView: View {
    @Binding var currentError: String?

    var body: some View {
        TileView(iconName: "exclamationmark.circle") {
            Text(currentError ?? "No error").font(FOOTNOTE_FONT)
                .frame(alignment: .leading)
        }
        .foregroundColor(ERROR_COLOR)
        .onTapGesture { currentError = nil }
        // Keep dimesions when hidden
        .opacity(currentError != nil ? 1.0 : 0.0)
    }
}
