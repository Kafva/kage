import SwiftUI

struct ErrorTileView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TileView(iconName: "exclamationmark.circle") {
            Text(appState.currentError ?? "Unknown error").font(G.captionFont)
                .foregroundColor(G.errorColor)
                .frame(alignment: .leading)
        }
        .onTapGesture { appState.currentError = nil }
    }
}
