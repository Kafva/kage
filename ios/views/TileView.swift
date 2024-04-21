import SwiftUI

struct TileView<Content: View>: View {
    let iconName: String?
    @ViewBuilder let content: Content

    var body: some View {
        let width = G.screenWidth*0.1
        return HStack {
            Image(systemName: iconName ?? "globe").opacity(iconName != nil ? 1.0 : 0.0)
                                                  .frame(width: width, alignment: .leading)
            content
        }
    }
}

