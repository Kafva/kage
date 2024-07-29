import SwiftUI

struct MessageView: View {
    let type: MessageType

    enum MessageType: String {
        case noSearchMatches = "No matches found"
        case empty = "Empty password repoistory"
    }

    private var iconSystemName: String {
        switch type {
        case .noSearchMatches:
            return "rays"
        case .empty:
            return "rays"
        }
    }

    var body: some View {
        return VStack(alignment: .center, spacing: 5) {
            Image(systemName: iconSystemName)
                .font(.system(size: 20.0))

            Text(self.type.rawValue)
                .font(.system(size: 16.0))
                .bold()
        }
        .foregroundColor(.gray)
        .frame(width: 0.8 * G.screenWidth)
    }
}
