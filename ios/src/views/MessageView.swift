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
                .font(.title2)  // Scaling size

            Text(self.type.rawValue)
                .font(.body)  // Scaling size
        }
        .foregroundColor(.gray)
        .frame(width: 0.8 * G.screenWidth)
    }
}
