import SwiftUI

struct TileView<Content: View>: View {
    let iconName: String?
    @ViewBuilder let content: Content
    @Environment(\.screenDims) var screenDims

    var body: some View {
        let width = 0.1 * screenDims.width
        return HStack {
            Image(systemName: iconName ?? "globe").opacity(
                iconName != nil ? 1.0 : 0.0
            )
            .frame(width: width, alignment: .leading)
            content
        }
    }
}
